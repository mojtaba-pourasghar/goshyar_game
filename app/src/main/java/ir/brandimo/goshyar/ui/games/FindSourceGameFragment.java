package ir.brandimo.goshyar.ui.games;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import ir.brandimo.goshyar.audio.AudioManagerHelper;
import ir.brandimo.goshyar.databinding.FragmentGameFindSourceBinding;
import ir.brandimo.goshyar.ui.dialogs.FeedbackTryAgainDialog;
import ir.brandimo.goshyar.ui.dialogs.RewardSuccessDialog;

public class FindSourceGameFragment extends Fragment {

    private FragmentGameFindSourceBinding binding;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        binding = FragmentGameFindSourceBinding.inflate(inflater, container, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        binding.btnPlaySound.setOnClickListener(v -> {
            binding.soundWaveView.startAnimation();
            AudioManagerHelper.getInstance().playTone(587.33, 500); // D5 Tone
        });

        binding.btnOptionCave.setOnClickListener(v -> {
            AudioManagerHelper.getInstance().playSuccessSound();
            RewardSuccessDialog dialog = new RewardSuccessDialog();
            dialog.show(getParentFragmentManager(), "RewardDialog");
        });

        binding.btnOptionForest.setOnClickListener(v -> showFeedback());
        binding.btnOptionRiver.setOnClickListener(v -> showFeedback());
        binding.btnOptionHouse.setOnClickListener(v -> showFeedback());
    }

    private void showFeedback() {
        AudioManagerHelper.getInstance().playFailSound();
        FeedbackTryAgainDialog dialog = new FeedbackTryAgainDialog();
        dialog.show(getParentFragmentManager(), "FeedbackDialog");
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        binding = null;
    }
}
