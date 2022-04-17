package l42server;

import org.json.JSONObject;

class Result {
    public long executionTimeNanos = -1;
    public String stdout;
    public String stderr;
    public int returnCode;

    public Result(String stdout, String stderr, int returnCode) {
        this.stdout = stdout;
        this.stderr = stderr;
        this.returnCode = returnCode;
    }

    public double executionTime() {
        return Math.round(executionTimeNanos / 1e6) / 1e3;
    }

    public String formattedTime() {
        return String.format("%.03f", executionTime());
    }

    public JSONObject toJSON() {
        var response = new JSONObject();
        response.put("ok", true);
        response.put("stdout", stdout);
        response.put("stderr", stderr);
        response.put("returncode", returnCode);
        response.put("duration", formattedTime());
        return response;
    }
}
