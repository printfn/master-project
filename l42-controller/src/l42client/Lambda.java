package l42client;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestStreamHandler;
import org.json.JSONObject;
import org.json.JSONTokener;

import java.io.*;
import java.nio.charset.StandardCharsets;

/// AWS Lambda entry point
public class Lambda implements RequestStreamHandler {
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

        var result = new JSONObject();
        result.put("ok", true);
        result.put("event", event);
        result.put("context", context);
        return result;
    }
}
