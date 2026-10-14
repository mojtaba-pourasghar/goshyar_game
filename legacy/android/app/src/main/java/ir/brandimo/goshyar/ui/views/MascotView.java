package ir.brandimo.goshyar.ui.views;

import android.content.Context;
import android.util.AttributeSet;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.widget.AppCompatImageView;
import ir.brandimo.goshyar.R;

public class MascotView extends AppCompatImageView {

    public enum Pose {
        IDLE, LISTENING, THINKING, HAPPY, CELEBRATING, ENCOURAGING, SURPRISED, SLEEPING
    }

    public MascotView(@NonNull Context context) {
        super(context);
        setPose(Pose.IDLE);
    }

    public MascotView(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        setPose(Pose.IDLE);
    }

    public void setPose(Pose pose) {
        int resId = R.drawable.mascot_idle;
        switch (pose) {
            case LISTENING: resId = R.drawable.mascot_listening; break;
            case THINKING: resId = R.drawable.mascot_thinking; break;
            case HAPPY: resId = R.drawable.mascot_happy; break;
            case CELEBRATING: resId = R.drawable.mascot_celebrating; break;
            case ENCOURAGING: resId = R.drawable.mascot_encouraging; break;
            case SURPRISED: resId = R.drawable.mascot_surprised; break;
            case SLEEPING: resId = R.drawable.mascot_sleeping; break;
            default: resId = R.drawable.mascot_idle; break;
        }
        setImageResource(resId);
    }
}
