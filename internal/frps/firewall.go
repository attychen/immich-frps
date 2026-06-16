package frps

import (
	"encoding/json"
	"log"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"sync"

	"github.com/xxl6097/go-frp-panel/pkg/comm"
)

type FirewallMode string

const (
	ModeBlacklist FirewallMode = "blacklist"
	ModeWhitelist FirewallMode = "whitelist"
)

type Firewall struct {
	mu        sync.RWMutex
	path      string
	Mode      FirewallMode    `json:"mode"`
	Blacklist map[string]bool `json:"blacklist"`
	Whitelist map[string]bool `json:"whitelist"`
}

func NewFirewall(dataDir string) *Firewall {
	fw := &Firewall{
		path:      filepath.Join(dataDir, "firewall.json"),
		Mode:      ModeBlacklist,
		Blacklist: make(map[string]bool),
		Whitelist: make(map[string]bool),
	}
	fw.load()
	return fw
}

func (fw *Firewall) save() error {
	dir := filepath.Dir(fw.path)
	if err := os.MkdirAll(dir, 0755); err != nil {
		log.Printf("WARN: firewall mkdir: %v", err)
		return err
	}
	data, _ := json.MarshalIndent(fw, "", "  ")
	return os.WriteFile(fw.path, data, 0644)
}

func (fw *Firewall) load() {
	data, _ := os.ReadFile(fw.path)
	json.Unmarshal(data, fw)
}

func (fw *Firewall) IsAllowed(ip string) bool {
	fw.mu.RLock()
	defer fw.mu.RUnlock()
	if fw.Mode == ModeWhitelist {
		return fw.matchAny(ip, fw.Whitelist)
	}
	return !fw.matchAny(ip, fw.Blacklist)
}

func (fw *Firewall) matchAny(ip string, rules map[string]bool) bool {
	for rule := range rules {
		if fw.matchIP(ip, rule) {
			return true
		}
	}
	return false
}

func (fw *Firewall) matchIP(ip, rule string) bool {
	if !strings.Contains(rule, "/") {
		return ip == rule
	}
	_, cidr, err := net.ParseCIDR(rule)
	if err != nil {
		return ip == rule
	}
	p := net.ParseIP(ip)
	if p == nil {
		return false
	}
	return cidr.Contains(p)
}

func (fw *Firewall) AddRule(ip string) error {
	fw.mu.Lock()
	defer fw.mu.Unlock()
	if fw.Mode == ModeBlacklist {
		fw.Blacklist[ip] = true
	} else {
		fw.Whitelist[ip] = true
	}
	return fw.save()
}

func (fw *Firewall) RemoveRule(ip string) error {
	fw.mu.Lock()
	defer fw.mu.Unlock()
	if fw.Mode == ModeBlacklist {
		delete(fw.Blacklist, ip)
	} else {
		delete(fw.Whitelist, ip)
	}
	return fw.save()
}

// ── API Handlers ──

func (this *frps) apiFirewallModeGet(w http.ResponseWriter, r *http.Request) {
	res, f := comm.Response(r)
	defer f(w)
	res.Any(map[string]interface{}{"mode": this.firewall.Mode})
}

func (this *frps) apiFirewallModeSet(w http.ResponseWriter, r *http.Request) {
	res, f := comm.Response(r)
	defer f(w)
	var req struct{ Mode FirewallMode `json:"mode"` }
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		res.Error("invalid request")
		return
	}
	if req.Mode != ModeBlacklist && req.Mode != ModeWhitelist {
		res.Error("mode must be blacklist or whitelist")
		return
	}
	this.firewall.Mode = req.Mode
	this.firewall.save()
	res.Ok("OK")
}

func (this *frps) apiFirewallRulesGet(w http.ResponseWriter, r *http.Request) {
	res, f := comm.Response(r)
	defer f(w)
	rules := this.firewall.Blacklist
	if this.firewall.Mode == ModeWhitelist {
		rules = this.firewall.Whitelist
	}
	res.Any(map[string]interface{}{"mode": this.firewall.Mode, "rules": rules})
}

func (this *frps) apiFirewallAdd(w http.ResponseWriter, r *http.Request) {
	res, f := comm.Response(r)
	defer f(w)
	var req struct{ IP string `json:"ip"` }
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		res.Error("invalid request")
		return
	}
	if req.IP == "" {
		res.Error("ip required")
		return
	}
	if err := this.firewall.AddRule(req.IP); err != nil {
		res.Error("add failed: " + err.Error())
		return
	}
	res.Ok("OK")
}

func (this *frps) apiFirewallRemove(w http.ResponseWriter, r *http.Request) {
	res, f := comm.Response(r)
	defer f(w)
	ip := r.URL.Query().Get("ip")
	if ip == "" {
		res.Error("ip required")
		return
	}
	if err := this.firewall.RemoveRule(ip); err != nil {
		res.Error("remove failed: " + err.Error())
		return
	}
	res.Ok("OK")
}

func (this *frps) apiFirewallCheck(w http.ResponseWriter, r *http.Request) {
	res, f := comm.Response(r)
	defer f(w)
	var req struct{ IP string `json:"ip"` }
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		res.Error("invalid request")
		return
	}
	allowed := this.firewall.IsAllowed(req.IP)
	res.Any(map[string]interface{}{"ip": req.IP, "allowed": allowed})
}
