package frps

import (
	"encoding/json"
	"io"
	"net/http"
	"sync"

	"github.com/xxl6097/go-frp-panel/pkg/comm"
	"github.com/xxl6097/go-frp-panel/pkg/diagnostic"
)

var (
	lastReport   *diagnostic.DiagnosticReport
	lastReportMu sync.RWMutex
)

// POST /api/diagnostic/run - 运行诊断
func (this *frps) apiDiagnosticRun(w http.ResponseWriter, r *http.Request) {
	res, f := comm.Response(r)
	defer f(w)

	var req struct {
		Ports []int `json:"ports"`
	}
	body, _ := io.ReadAll(r.Body)
	if len(body) > 0 {
		json.Unmarshal(body, &req)
	}

	report := diagnostic.RunDiagnostic(req.Ports)

	lastReportMu.Lock()
	lastReport = report
	lastReportMu.Unlock()

	res.Any(report)
}

// GET /api/diagnostic/report - 获取最近报告
func (this *frps) apiDiagnosticReport(w http.ResponseWriter, r *http.Request) {
	res, f := comm.Response(r)
	defer f(w)

	lastReportMu.RLock()
	report := lastReport
	lastReportMu.RUnlock()

	if report == nil {
		res.Error("暂无诊断报告，请先运行诊断")
		return
	}
	res.Any(report)
}
