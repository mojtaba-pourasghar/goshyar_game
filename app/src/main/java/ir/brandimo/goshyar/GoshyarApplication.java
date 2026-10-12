package ir.brandimo.goshyar;

import android.app.Application;
import ir.brandimo.goshyar.audio.AudioManagerHelper;

public class GoshyarApplication extends Application {

    @Override
    public void onCreate() {
        super.onCreate();
        AudioManagerHelper.getInstance().init(this);
    }
}
