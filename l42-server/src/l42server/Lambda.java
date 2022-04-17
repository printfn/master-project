package l42server;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestStreamHandler;
import org.json.JSONObject;
import org.json.JSONTokener;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.util.Base64;

/// AWS Lambda entry point
public class Lambda implements RequestStreamHandler {
    L42 client = new L42(Path.of("/tmp/L42testing"));

    String getPath(JSONObject event) {
        if (!event.has("requestContext"))
            return null;
        var requestContext = event.getJSONObject("requestContext");
        if (!requestContext.has("http"))
            return null;
        var http = requestContext.getJSONObject("http");
        if (!http.has("path"))
            return null;
        return http.getString("path");
    }

    public void handleRequest(InputStream inputStream, OutputStream outputStream, Context context) throws IOException {
        var reader = new BufferedReader(new InputStreamReader(inputStream, StandardCharsets.UTF_8));
        var writer = new PrintWriter(new BufferedWriter(new OutputStreamWriter(outputStream, StandardCharsets.UTF_8)));
        var tokener = new JSONTokener(reader);
        LambdaLogger logger = context.getLogger();
        try {
            var eventObj = new JSONObject(tokener);
            JSONObject resultBody;
            var statusCode = 200;
            switch (getPath(eventObj)) {
                case "/execute":
                    resultBody = executeHandler(eventObj, logger);
                    break;
                case "/health":
                    resultBody = new JSONObject();
                    resultBody.put("ok", true);
                    break;
                default:
                    resultBody = new JSONObject();
                    resultBody.put("ok", false);
                    resultBody.put("message", "404 Not Found");
                    statusCode = 400;
                    break;
            }
            var result = new JSONObject();
            result.put("body", resultBody);
            result.put("statusCode", statusCode);
            var headers = new JSONObject();
            headers.put("Access-Control-Allow-Origin", "*");
            result.put("headers", headers);
            writer.write(result.toString());
            logger.log("Response: \n" + result);
            if (writer.checkError()) {
                logger.log("WARNING: Writer encountered an error.");
            }
        } catch (Exception e) {
            logger.log(e.toString());
        } finally {
            reader.close();
            writer.close();
        }
    }

    public JSONObject executeHandler(JSONObject event, LambdaLogger logger) {
        logger.log("Event: " + event);

        try {
            if (event.has("isBase64Encoded") && event.getBoolean("isBase64Encoded")) {
                var base64 = event.getString("body");
                var body = new String(Base64.getDecoder().decode(base64), StandardCharsets.UTF_8);
                var bodyTokener = new JSONTokener(body);
                event = new JSONObject(bodyTokener);
            } else if (event.has("body")) {
                // When calling this Lambda via API Gateway, we need to read out the HTTP request body
                // from the "body" element
                var body = event.getString("body");
                var bodyTokener = new JSONTokener(body);
                event = new JSONObject(bodyTokener);
            }

            var code = event.getString("code");

            logger.log("Received code: " + code);
            return client.runL42FromCode(code).toJSON();
        } catch (Exception e) {
            logger.log(e.toString());
            var response = new JSONObject();
            response.put("ok", false);
            response.put("message", e.toString());
            return response;
        }
    }
}
