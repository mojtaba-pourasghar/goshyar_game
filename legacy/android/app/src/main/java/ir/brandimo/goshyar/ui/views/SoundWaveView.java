package ir.brandimo.goshyar.ui.views;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.RectF;
import android.util.AttributeSet;
import android.view.View;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;
import ir.brandimo.goshyar.R;

public class SoundWaveView extends View {

    private Paint paint;
    private boolean isPlaying = false;
    private float[] barHeights = new float[]{0.3f, 0.6f, 0.9f, 0.5f, 0.8f, 0.4f, 0.7f};
    private float animationPhase = 0f;

    public SoundWaveView(Context context) {
        super(context);
        init();
    }

    public SoundWaveView(Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        init();
    }

    private void init() {
        paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        paint.setColor(ContextCompat.getColor(getContext(), R.color.turquoise_accent));
        paint.setStyle(Paint.Style.FILL);
    }

    public void startAnimation() {
        isPlaying = true;
        invalidate();
    }

    public void stopAnimation() {
        isPlaying = false;
        invalidate();
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);

        int w = getWidth();
        int h = getHeight();
        int barCount = barHeights.length;
        float barWidth = w / (float) (barCount * 2 - 1);
        float gap = barWidth;

        for (int i = 0; i < barCount; i++) {
            float heightFactor = barHeights[i];
            if (isPlaying) {
                heightFactor = (float) Math.abs(Math.sin(animationPhase + i * 0.8f));
            }

            float barH = h * heightFactor * 0.8f;
            float left = i * (barWidth + gap);
            float top = (h - barH) / 2f;
            float right = left + barWidth;
            float bottom = top + barH;

            RectF rect = new RectF(left, top, right, bottom);
            canvas.drawRoundRect(rect, barWidth / 2f, barWidth / 2f, paint);
        }

        if (isPlaying) {
            animationPhase += 0.15f;
            postInvalidateDelayed(40);
        }
    }
}
