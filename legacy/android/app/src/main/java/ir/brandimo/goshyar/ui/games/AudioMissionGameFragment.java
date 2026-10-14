package ir.brandimo.goshyar.ui.games;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.google.android.material.button.MaterialButton;

import java.util.ArrayList;
import java.util.List;

import ir.brandimo.goshyar.R;
import ir.brandimo.goshyar.data.GameContent;
import ir.brandimo.goshyar.data.GameLevel;
import ir.brandimo.goshyar.data.GameMode;
import ir.brandimo.goshyar.data.SoundItem;
import ir.brandimo.goshyar.databinding.FragmentGameAudioMissionBinding;
import ir.brandimo.goshyar.ui.views.MascotView;

/**
 * بازی ۴ — «مأموریت شنیداری»: چند صدا با هم و لایه‌لایه در یک صحنه پخش می‌شود
 * و کودک باید بشمارد چند صدای مختلف می‌شنود.
 */
public class AudioMissionGameFragment extends BaseGameFragment {

    private FragmentGameAudioMissionBinding binding;

    @Override
    protected String modeId() { return GameMode.AUDIO_MISSION; }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        binding = FragmentGameAudioMissionBinding.inflate(inflater, container, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        binding.btnGameBack.setOnClickListener(v -> goHome());
        binding.btnStartMission.setOnClickListener(v -> playScene());
        super.onViewCreated(view, savedInstanceState);
    }

    @Override
    protected void bindLevel(GameLevel level) {
        binding.tvLevelCounter.setText(getString(R.string.game_progress, level.number, mode.levelCount()));
        binding.stepProgress.setProgress(levelIndex, mode.levelCount());
        binding.tvSceneTitle.setText(level.sceneTitle == null ? "" : level.sceneTitle);
        binding.imgScene.setImageResource(GameContent.drawableId(requireContext(),
                level.backgroundName, R.drawable.bg_sunny_forest));
        binding.mascotMission.setPose(MascotView.Pose.LISTENING);

        buildCountOptions(level);
        audio.playVoice(level.voiceId, this::playScene);
    }

    /** دکمه‌های عددی: کودک تعداد صداهای شنیده‌شده را انتخاب می‌کند. */
    private void buildCountOptions(GameLevel level) {
        LinearLayout row = binding.rowCountOptions;
        row.removeAllViews();

        for (int option : level.countOptions) {
            MaterialButton b = new MaterialButton(requireContext());
            b.setText(String.valueOf(option));
            b.setTextSize(20f);
            b.setAllCaps(false);
            b.setCornerRadius(24);
            b.setBackgroundTintList(
                    androidx.core.content.ContextCompat.getColorStateList(requireContext(), R.color.purple_medium));

            LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(0,
                    ViewGroup.LayoutParams.WRAP_CONTENT, 1f);
            lp.setMargins(8, 0, 8, 0);
            b.setLayoutParams(lp);

            final int value = option;
            b.setOnClickListener(v -> {
                if (answered) return;
                audio.playTapSound();
                boolean correct = value == level.answerCount;
                b.setBackgroundTintList(androidx.core.content.ContextCompat.getColorStateList(
                        requireContext(), correct ? R.color.success_green : R.color.error_red));
                binding.mascotMission.setPose(
                        correct ? MascotView.Pose.CELEBRATING : MascotView.Pose.ENCOURAGING);
                submitAnswer(correct);
            });
            row.addView(b);
        }
    }

    /** لایه‌های صوتی صحنه را با فاصله کوتاه روی هم پخش می‌کند. */
    private void playScene() {
        GameLevel level = currentLevel();
        if (level == null) return;
        List<String> paths = new ArrayList<>();
        for (String id : level.layers) {
            SoundItem s = content.sound(id);
            if (s != null) paths.add(s.audioPath);
        }
        audio.playLayered(paths);
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        binding = null;
    }
}
