package l42client;

import org.json.JSONObject;

public record Result(long executionTimeNanos, String stdout, String stderr) {
    public double executionTime() {
        return Math.round(executionTimeNanos() / 1e6) / 1e3;
    }

    public String formattedTime() {
        return String.format("Time: %.3f s", executionTime());
    }

    public JSONObject toJSON() {
        var response = new JSONObject();
        response.put("ok", true);
        response.put("stdout", stdout());
        response.put("stderr", stderr());
        response.put("returncode", 0); // TODO
        response.put("duration", executionTime());
        return response;
    }
}
