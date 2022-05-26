package l42server;

import is.L42.platformSpecific.javaTranslation.Resources;

import java.io.Serializable;

class OutputHandler implements Serializable {
    StringBuilder stdout = new StringBuilder();
    StringBuilder stderr = new StringBuilder();
    StringBuilder tests = new StringBuilder();

    void setHandlers() {
        Resources.setOutHandler(s -> {
            synchronized (OutputHandler.class) {
                stdout.append(s);
                System.out.println("outHandler: " + s);
            }
        });
        Resources.setErrHandler(s -> {
            synchronized (OutputHandler.class) {
                System.out.println("errHandler " + s);
                stderr.append(s);
            }
        });
        Resources.setTestHandler(s -> {
            synchronized (OutputHandler.class) {
                System.out.println("testHandler " + s);
                tests.append(s);
            }
        });
    }
}
