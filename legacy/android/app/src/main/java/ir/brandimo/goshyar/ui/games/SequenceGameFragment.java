package ir.brandimo.goshyar.ui.games;

import android.os.Bundle;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.GridLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import ir.brandimo.goshyar.R;
import ir.brandimo.goshyar.data.GameContent;
import ir.brandimo.goshyar.data.GameLevel;
import ir.brandimo.goshyar.data.GameMode;
import ir.brandimo.goshyar.data.SoundItem;
import ir.brandimo.goshyar.databinding.FragmentGameSequenceBinding;

/**
 * بازی ۳ — «ترتیب صداها»: چند صدا پشت سر هم پخش می‌شود و کودک باید
 * همان ترتیب را با زدن روی کارت‌های بُرخورده بازسازی کند.
 */
public class SequenceGameFragment extends BaseGameFragment {

    private FragmentGameSequenceBinding binding;
    private final List<String> picked = new ArrayList<>();

    @Override
    protected String modeId() { return GameMode.SEQUENCE; }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        binding = FragmentGameSequenceBinding.inflate(inflater, container, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        binding.btnGameBack.setOnClickListener(v -> goHome());
        binding.btnPlaySequence.setOnClickListener(v -> playSequence());
        binding.btnClearSequence.setOnClickListener(v -> { picked.clear(); refreshPicked(); });
        binding.btnVerifySequence.setOnClickListener(v -> verify());
        super.onViewCreated(view, savedInstanceState);
    }

    @Override
    protected void bindLevel(GameLevel level) {
        picked.clear();
        binding.tvLevelCounter.setText(getString(R.string.game_progress, level.number, mode.levelCount()));
        binding.stepProgress.setProgress(levelIndex, mode.levelCount());

        buildChoices(level);
        refreshPicked();

        audio.playVoice(level.voiceId, this::playSequence);
    }

    /** کارت‌های انتخاب، به ترتیبِ بُرخورده تا پاسخ از روی چیدمان لو نرود. */
    private void buildChoices(GameLevel level) {
        GridLayout grid = binding.gridChoices;
        grid.removeAllViews();

        List<String> ids = new ArrayList<>(level.sequence);
        Collections.shuffle(ids);
        grid.setColumnCount(Math.min(3, Math.max(1, ids.size())));

        LayoutInflater inflater = LayoutInflater.from(requireContext());
        for (String soundId : ids) {
            SoundItem s = content.sound(soundId);
            if (s == null) continue;

            View card = inflater.inflate(R.layout.item_option_card, grid, false);
            GridLayout.LayoutParams lp = new GridLayout.LayoutParams(card.getLayoutParams());
            lp.width = 0;
            lp.columnSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f);
            card.setLayoutParams(lp);

            ((TextView) card.findViewById(R.id.tv_option)).setText(s.title);
            ((ImageView) card.findViewById(R.id.img_option)).setImageResource(
                    GameContent.drawableId(requireContext(), s.imageName, R.drawable.mascot_thinking));

            card.setOnClickListener(v -> {
                if (answered || picked.size() >= level.sequence.size()) return;
                audio.playSfx(s.audioPath);
                picked.add(soundId);
                refreshPicked();
            });
            grid.addView(card);
        }
    }

    /** ردیف بالا: چیزهایی که کودک تا الان انتخاب کرده است. */
    private void refreshPicked() {
        LinearLayout row = binding.rowPicked;
        row.removeAllViews();

        GameLevel level = currentLevel();
        int need = level != null ? level.sequence.size() : 0;

        for (int i = 0; i < picked.size(); i++) {
            SoundItem s = content.sound(picked.get(i));
            if (s == null) continue;

            LinearLayout cell = new LinearLayout(requireContext());
            cell.setOrientation(LinearLayout.VERTICAL);
            cell.setGravity(Gravity.CENTER);
            LinearLayout.LayoutParams lp =
                    new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, 1f);
            cell.setLayoutParams(lp);

            ImageView img = new ImageView(requireContext());
            img.setLayoutParams(new LinearLayout.LayoutParams(48, 48, 1f));
            img.setAdjustViewBounds(true);
            img.setImageResource(GameContent.drawableId(requireContext(), s.imageName,
                    R.drawable.mascot_thinking));

            TextView num = new TextView(requireContext());
            num.setText(String.valueOf(i + 1));
            num.setGravity(Gravity.CENTER);
            num.setTextSize(13f);

            cell.addView(img);
            cell.addView(num);
            row.addView(cell);
        }

        binding.btnVerifySequence.setEnabled(!answered && need > 0 && picked.size() == need);
    }

    private void playSequence() {
        GameLevel level = currentLevel();
        if (level == null) return;
        List<String> paths = new ArrayList<>();
        for (String id : level.sequence) {
            SoundItem s = content.sound(id);
            if (s != null) paths.add(s.audioPath);
        }
        audio.playSequence(paths, 350, null);
    }

    private void verify() {
        GameLevel level = currentLevel();
        if (level == null || answered) return;
        boolean correct = picked.equals(level.sequence);
        if (!correct) {
            picked.clear();
            refreshPicked();
        }
        submitAnswer(correct);
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        picked.clear();
        binding = null;
    }
}
