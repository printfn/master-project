package l42server;

import is.L42.platformSpecific.javaTranslation.Resources;

import java.io.Serializable;

class OutputHandler implements Serializable {
    StringBuilder stdout = new StringBuilder();
    StringBuilder stderr = new StringBuilder();

    void setHandlers() {
        Resources.setOutHandler(s -> {
            synchronized (OutputHandler.class) {
                stdout.append(s);
                System.out.println("outHandler: " + s);
            }
        });
        Resources.setErrHandler(s -> {
            synchronized (OutputHandler.class) {
                System.out.println("RECEIVED " + s);
                stderr.append(s);
            }
        });
    }
}
