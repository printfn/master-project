package l42client;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestStreamHandler;
import org.json.JSONObject;
import org.json.JSONTokener;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;

/// AWS Lambda entry point
public class Lambda implements RequestStreamHandler {
    L42Client client = new L42Client(Path.of("/tmp/L42testing"));

    public void handleRequest(InputStream inputStream, OutputStream outputStream, Context context) throws IOException {
        var reader = new BufferedReader(new InputStreamReader(inputStream, StandardCharsets.UTF_8));
        var writer = new PrintWriter(new BufferedWriter(new OutputStreamWriter(outputStream, StandardCharsets.UTF_8)));
        var tokener = new JSONTokener(reader);
        LambdaLogger logger = context.getLogger();
        try {
            JSONObject eventObj = new JSONObject(tokener);
            JSONObject result = handler(eventObj, context, logger);
            writer.write(result.toString());
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

    public JSONObject handler(JSONObject event, Context context, LambdaLogger logger) {
        logger.log("Event: " + event);

        // When calling this Lambda via API Gateway, we need to read out the HTTP request body
        // from the "body" element
        if (event.has("body")) {
            var body = event.getString("body");
            var bodyTokener = new JSONTokener(body);
            event = new JSONObject(bodyTokener);
        }

        var code = event.getString("code");

        logger.log("Received code: " + code);
        return client.runL42FromCode(code).toJSON();
    }
}
