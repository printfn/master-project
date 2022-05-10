package l42server;

import com.amazonaws.lambda.thirdparty.org.json.JSONObject;
import com.amazonaws.lambda.thirdparty.org.json.JSONTokener;
import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestStreamHandler;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.Base64;

// This Lambda handler can be called with two types of events:
// scheduled events and HTTP requests

// Scheduled events look like this:
// { "detail-type":"Scheduled Event",
//   "resources":["arn:aws:events:eu-central-1:307210808327:rule/every-ten-minutes"],
//   "id":"e39837a7-6b1f-cd2e-217b-a1ce76cd2f0a",
//   "source":"aws.events","time":"2022-04-24T15:59:36Z",
//   "detail":{},"region":"eu-central-1","version":"0","account":"307210808327" }

// HTTP Requests look like this:
// { "headers":{"content-type":"text/plain;charset=UTF-8"},
//   "isBase64Encoded":false,"rawPath":"/execute",
//   "routeKey":"$default",
//   "requestContext":{
//       "accountId":"anonymous","timeEpoch":1650815743343,"routeKey":"$default",
//       "stage":"$default","domainPrefix":"ropr2kskcqziasbmulr45x23fm0bujfj",
//       "requestId":"dd3bb0a9-7fce-4d90-82bf-9a5a15a867ab",
//       "http":{ "path":"/execute","protocol":"HTTP/1.1","method":"POST" } },
//   "body":"...","version":"2.0","rawQueryString":"" }

/// AWS Lambda entry point
public class Lambda implements RequestStreamHandler {
    L42 client = new L42(Path.of("/tmp/L42testing"), false);

    JSONObject SCHEDULED_EVENT = new JSONObject().put("type", "Scheduled Event");

    /// this is expected to return "Scheduled Event", "/execute" or "/health"
    /// (but it can return other strings for invalid/unknown requests)
    String getPath(JSONObject event) {
        if (event.has("detail-type")) {
            return event.getString("detail-type");
        }
        if (!event.has("requestContext"))
            return "";
        var requestContext = event.getJSONObject("requestContext");
        if (!requestContext.has("http"))
            return "";
        var http = requestContext.getJSONObject("http");
        if (!http.has("path"))
            return "";
        return http.getString("path");
    }

    public void handleRequest(InputStream inputStream, OutputStream outputStream, Context context) throws IOException {
        var reader = new BufferedReader(new InputStreamReader(inputStream, StandardCharsets.UTF_8));
        var writer = new PrintWriter(new BufferedWriter(new OutputStreamWriter(outputStream, StandardCharsets.UTF_8)));
        LambdaLogger logger = context.getLogger();
        try {
            var eventObj = new JSONObject(new JSONTokener(reader));
            logger.log("Event: " + eventObj + "\n");
            JSONObject resultBody;
            var statusCode = 200;
            switch (getPath(eventObj)) {
                case "Scheduled Event":
                    resultBody = executeHandler(SCHEDULED_EVENT, logger);
                    break;
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

            // We don't need to set the CORS header here because it's set
            // in the AWS Lambda Function URL configuration instead
            // (via terraform). In fact, setting this header twice causes
            // web browsers to reject cross-origin requests.
            // See https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS/Errors/CORSAllowOriginNotMatchingOrigin
            // for details.

            //headers.put("Access-Control-Allow-Origin", "*");
            result.put("headers", headers);
            writer.write(result.toString());
            logger.log("Response: \n" + result);
            if (writer.checkError()) {
                logger.log("WARNING: Writer encountered an error.");
            }
        } catch (Exception e) {
            logger.log(e.toString());
            logger.log(Arrays.toString(e.getStackTrace()));
        } finally {
            reader.close();
            writer.close();
        }
    }

    public JSONObject executeHandler(JSONObject event, LambdaLogger logger) {
        try {
            if (event.has("type") && event.get("type") == "Scheduled Event") {
                event = L42.HELLO_WORLD;
            } else if (event.has("isBase64Encoded") && event.getBoolean("isBase64Encoded")) {
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

            logger.log("Received input: " + event + "\n");
            return client.runL42FromCode(event).toJSON();
        } catch (Exception e) {
            logger.log(e.toString());
            var response = new JSONObject();
            response.put("ok", false);
            response.put("message", e.toString());
            return response;
        }
    }
}
