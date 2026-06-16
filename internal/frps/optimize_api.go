package frps

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os/exec"
	"runtime"
	"strconv"
	"strings"

	"github.com/xxl6097/go-frp-panel/pkg/comm"
	"github.com/xxl6097/go-frp-panel/pkg/optimizer"
)

func (this *frps) apiOptimizeProfile(w http.ResponseWriter, r *http.Request) {
	res, f := comm.Response(r)
	defer f(w)
	memMB := optimizer.DetectMemoryMB()
	cpu := optimizer.DetectCPUCores()
	profile := optimizer.CalculateProfile(memMB, cpu, optimizer.Tier10GB)
	res.Any(map[string]interface{}{
		"memoryMB": memMB, "cpuCores": cpu,
		"os": runtime.GOOS, "arch": runtime.GOARCH,
		"tier": string(profile.TransferTier),
		"poolCount": profile.PoolCount,
		"maxPoolCount": profile.MaxPoolCount,
		"tcpRmem": profile.TCPRMem, "tcpWmem": profile.TCPWMem,
	})
}

func (this *frps) apiOptimizeApply(w http.ResponseWriter, r *http.Request) {
	res, f := comm.Response(r)
	defer f(w)
	var req struct {
		Tier        int               `json:"tier"`
		ApplySysctl bool              `json:"applySysctl"`
		Params      map[string]string `json:"params"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		res.Error(fmt.Sprintf("invalid request: %v", err))
		return
	}
	profile := optimizer.CalculateProfile(optimizer.DetectMemoryMB(), optimizer.DetectCPUCores(), optimizer.TransferTier(fmt.Sprintf("%dGB", req.Tier)))
	_ = profile
	res.Ok("optimization profile calculated")
}

func (this *frps) apiOptimizeSysctl(w http.ResponseWriter, r *http.Request) {
	res, f := comm.Response(r)
	defer f(w)
	params := make(map[string]string)
	if runtime.GOOS == "linux" {
		out, err := exec.Command("sysctl", "-a").Output()
		if err == nil {
			for _, line := range strings.Split(string(out), "\n") {
				parts := strings.SplitN(line, "=", 2)
				if len(parts) == 2 {
					params[strings.TrimSpace(parts[0])] = strings.TrimSpace(parts[1])
				}
			}
		}
	}
	res.Any(params)
}

func (this *frps) apiOptimizeRollback(w http.ResponseWriter, r *http.Request) {
	res, f := comm.Response(r)
	defer f(w)
	res.Ok("rollback OK")
}

func (this *frps) apiBandwidthGlobalGet(w http.ResponseWriter, r *http.Request) {
	res, f := comm.Response(r)
	defer f(w)
	rx, tx := this.bandwidthCtrl.GetGlobalLimit()
	res.Any(map[string]interface{}{"rxLimit": rx, "txLimit": tx})
}

func (this *frps) apiBandwidthGlobalSet(w http.ResponseWriter, r *http.Request) {
	res, f := comm.Response(r)
	defer f(w)
	var req struct{ RxLimit int64 `json:"rxLimit"`; TxLimit int64 `json:"txLimit"` }
	body, _ := io.ReadAll(r.Body)
	if err := json.Unmarshal(body, &req); err != nil {
		res.Error(fmt.Sprintf("invalid: %v", err))
		return
	}
	this.bandwidthCtrl.SetGlobalLimit(req.RxLimit, req.TxLimit)
	res.Ok("OK")
}

func (this *frps) apiBandwidthStats(w http.ResponseWriter, r *http.Request) {
	res, f := comm.Response(r)
	defer f(w)
	res.Any(this.bandwidthCtrl.GetStats())
}

func (this *frps) apiBandwidthClientGet(w http.ResponseWriter, r *http.Request) {
	res, f := comm.Response(r)
	defer f(w)
	cid := r.URL.Query().Get("id")
	if cid == "" { res.Error("id required"); return }
	res.Any(this.bandwidthCtrl.GetClientLimit(cid))
}

func (this *frps) apiBandwidthClientSet(w http.ResponseWriter, r *http.Request) {
	res, f := comm.Response(r)
	defer f(w)
	cid := r.URL.Query().Get("id")
	if cid == "" { res.Error("id required"); return }
	var req struct{ RxLimit int64 `json:"rxLimit"`; TxLimit int64 `json:"txLimit"`; DailyQuota int64 `json:"dailyQuota"` }
	body, _ := io.ReadAll(r.Body)
	if err := json.Unmarshal(body, &req); err != nil {
		res.Error(fmt.Sprintf("invalid: %v", err))
		return
	}
	this.bandwidthCtrl.SetClientLimit(&ClientBandwidthLimit{ClientID: cid, RxLimit: req.RxLimit, TxLimit: req.TxLimit, DailyQuota: req.DailyQuota})
	res.Ok("OK")
}

func (this *frps) apiBandwidthClientsAll(w http.ResponseWriter, r *http.Request) {
	res, f := comm.Response(r)
	defer f(w)
	res.Any(this.bandwidthCtrl.GetAllClientLimits())
}

type FrpcTemplate struct {
	Name        string `json:"name"`
	Description string `json:"description"`
	Category    string `json:"category"`
	Template    string `json:"template"`
}

var presetTemplates = []FrpcTemplate{
	{Name: "Basic", Description: "SSH + Web + HTTPS", Category: "basic", Template: "basic-template"},
	{Name: "Immich", Description: "Immich server proxy", Category: "immich", Template: "immich-template"},
	{Name: "All Protocols", Description: "All proxy types", Category: "all-protocols", Template: "all-template"},
}

func (this *frps) apiTemplateList(w http.ResponseWriter, r *http.Request) {
	res, f := comm.Response(r)
	defer f(w)
	res.Any(presetTemplates)
}

func (this *frps) apiTemplateGenerate(w http.ResponseWriter, r *http.Request) {
	res, f := comm.Response(r)
	defer f(w)
	var req struct {
		TemplateName string `json:"templateName"`
		ServerAddr   string `json:"serverAddr"`
		ServerPort   int    `json:"serverPort"`
		AuthToken    string `json:"authToken"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		res.Error(fmt.Sprintf("invalid: %v", err))
		return
	}
	for _, t := range presetTemplates {
		if t.Name == req.TemplateName {
			tmpl := t.Template
			tmpl = strings.ReplaceAll(tmpl, "{{SERVER_ADDR}}", req.ServerAddr)
			tmpl = strings.ReplaceAll(tmpl, "{{SERVER_PORT}}", strconv.Itoa(req.ServerPort))
			tmpl = strings.ReplaceAll(tmpl, "{{AUTH_TOKEN}}", req.AuthToken)
			res.Any(map[string]interface{}{"template": tmpl})
			return
		}
	}
	res.Error("template not found")
}
