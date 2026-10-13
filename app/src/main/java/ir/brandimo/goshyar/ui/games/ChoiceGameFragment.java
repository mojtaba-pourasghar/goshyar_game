package ir.brandimo.goshyar.ui.games;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.GridLayout;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.cardview.widget.CardView;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import ir.brandimo.goshyar.R;
import ir.brandimo.goshyar.data.GameContent;
import ir.brandimo.goshyar.data.GameLevel;
import ir.brandimo.goshyar.data.SoundItem;
import ir.brandimo.goshyar.databinding.FragmentGameChoiceBinding;
import ir.brandimo.goshyar.ui.views.MascotView;

/**
 * پایه دو بازی گزینه‌ای: «پیدا کردن منبع صدا» و «این صدا مال کیه؟».
 * هر دو یک صدا پخش می‌کنند و کودک از بین کارت‌های تصویری یکی را انتخاب می‌کند.
 * گزینه‌ها در هر بار اجرا بُر می‌خورند تا جای جواب درست حفظ نشود.
 */
public abstract class ChoiceGameFragment extends BaseGameFragment {

    protected FragmentGameChoiceBinding binding;
    private final List<View> optionViews = new ArrayList<>();

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        binding = FragmentGameChoiceBinding.inflate(inflater, container, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        binding.btnGameBack.setOnClickListener(v -> goHome());
        binding.btnPlaySound.setOnClickListener(v -> playLevelSound());
        super.onViewCreated(view, savedInstanceState);
    }

    @Override
    protected void bindLevel(GameLevel level) {
        binding.tvGameTitle.setText(mode.title);
        binding.tvInstruction.setText(mode.instruction);
        binding.tvLevelCounter.setText(getString(R.string.game_progress, level.number, mode.levelCount()));
        binding.stepProgress.setProgress(levelIndex, mode.levelCount());
        binding.mascotGame.setPose(MascotView.Pose.LISTENING);

        buildOptions(level);

        // اول راهنمای گوینده، بعد خود صدا
        audio.playVoice(level.voiceId, this::playLevelSound);
    }

    private void buildOptions(GameLevel level) {
        GridLayout grid = binding.gridOptions;
        grid.removeAllViews();
        optionViews.clear();

        List<String> ids = new ArrayList<>(level.options);
        Collections.shuffle(ids);
        grid.setColumnCount(ids.size() <= 3 ? ids.size() : 2);

        LayoutInflater inflater = LayoutInflater.from(requireContext());
        for (String optionId : ids) {
            View card = inflater.inflate(R.layout.item_option_card, grid, false);

            GridLayout.LayoutParams lp = new GridLayout.LayoutParams(card.getLayoutParams());
            lp.width = 0;
            lp.columnSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f);
            card.setLayoutParams(lp);

            ImageView img = card.findViewById(R.id.img_option);
            TextView label = card.findViewById(R.id.tv_option);
            ImageView mark = card.findViewById(R.id.img_option_mark);

            label.setText(content.optionTitle(mode.id, optionId));
            img.setImageResource(GameContent.drawableId(requireContext(),
                    content.optionImage(mode.id, optionId), R.drawable.mascot_thinking));
            mark.setVisibility(View.INVISIBLE);

            card.setOnClickListener(v -> onOptionTapped(level, optionId, card, mark));
            grid.addView(card);
            optionViews.add(card);
        }
    }

    private void onOptionTapped(GameLevel level, String optionId, View card, ImageView mark) {
        if (answered) return;
        audio.playTapSound();

        boolean correct = optionId.equals(level.answerId);
        mark.setVisibility(View.VISIBLE);
        mark.setImageResource(correct ? R.drawable.ic_check_green : R.drawable.ic_close_red);
        if (card instanceof CardView) {
            ((CardView) card).setCardBackgroundColor(
                    getResources().getColor(correct ? R.color.success_green_soft : R.color.error_red_soft));
        }

        if (correct) {
            binding.mascotGame.setPose(MascotView.Pose.CELEBRATING);
            for (View v : optionViews) v.setClickable(false);
        } else {
            binding.mascotGame.setPose(MascotView.Pose.ENCOURAGING);
            card.setClickable(false);
        }
        submitAnswer(correct);
    }

    /** صدای این مرحله را پخش می‌کند و نوار موج را تکان می‌دهد. */
    protected void playLevelSound() {
        GameLevel level = currentLevel();
        if (level == null || level.soundId == null) return;
        SoundItem s = content.sound(level.soundId);
        if (s == null) return;

        binding.soundWaveView.startAnimation();
        audio.playSfx(s.audioPath, () -> {
            if (binding != null) binding.soundWaveView.stopAnimation();
        });
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        optionViews.clear();
        binding = null;
    }
}
