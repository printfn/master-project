package l42client;

import org.json.JSONObject;

public class Result {
    public long executionTimeNanos = -1;
    public String stdout;
    public String stderr;

    public Result(String stdout, String stderr) {
        this.stdout = stdout;
        this.stderr = stderr;
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
        response.put("returncode", 0); // TODO
        response.put("duration", formattedTime());
        return response;
    }
}
