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

/** نوار نقطه‌ای پیشرفت مرحله‌ها، مثل همان چیزی که در طرح اولیه بود. */
public class StepProgressView extends View {

    private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private int total = 1;
    private int current = 0;

    public StepProgressView(Context c) { super(c); }
    public StepProgressView(Context c, @Nullable AttributeSet a) { super(c, a); }

    public void setProgress(int currentIndex, int totalSteps) {
        this.current = currentIndex;
        this.total = Math.max(1, totalSteps);
        invalidate();
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        int w = getWidth(), h = getHeight();
        float gap = 6f;
        float segW = (w - gap * (total - 1)) / total;
        float r = h / 2f;

        for (int i = 0; i < total; i++) {
            boolean done = i < current;
            boolean active = i == current;
            int color = done
                    ? ContextCompat.getColor(getContext(), R.color.success_green)
                    : active
                        ? ContextCompat.getColor(getContext(), R.color.gooshi_orange)
                        : ContextCompat.getColor(getContext(), R.color.card_border);
            paint.setColor(color);
            float left = i * (segW + gap);
            canvas.drawRoundRect(new RectF(left, 0, left + segW, h), r, r, paint);
        }
    }
}
