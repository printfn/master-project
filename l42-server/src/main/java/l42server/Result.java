package l42server;

import com.amazonaws.lambda.thirdparty.org.json.JSONObject;

import java.io.Serializable;

class Result implements Serializable {
    public long executionTimeNanos = -1;
    public String stdout;
    public String stderr;
    public String tests;
    public int returnCode;

    public Result(String stdout, String stderr, String tests, int returnCode) {
        this.stdout = stdout;
        this.stderr = stderr;
        this.tests = tests;
        this.returnCode = returnCode;
    }

    public static Result fromErrorMessage(String err) {
        return new Result("", err, "", 1);
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
        response.put("tests", tests);
        response.put("returncode", returnCode);
        response.put("duration", formattedTime());
        return response;
    }
}
