package ir.brandimo.goshyar.ui.games;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import ir.brandimo.goshyar.audio.AudioManagerHelper;
import ir.brandimo.goshyar.databinding.FragmentGameWhoMadeSoundBinding;
import ir.brandimo.goshyar.ui.dialogs.FeedbackTryAgainDialog;
import ir.brandimo.goshyar.ui.dialogs.RewardSuccessDialog;

public class WhoMadeSoundGameFragment extends Fragment {

    private FragmentGameWhoMadeSoundBinding binding;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        binding = FragmentGameWhoMadeSoundBinding.inflate(inflater, container, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        binding.btnPlayAnimalSound.setOnClickListener(v -> {
            AudioManagerHelper.getInstance().playTone(300, 400); // Lion roar tone
        });

        binding.btnChoiceLion.setOnClickListener(v -> {
            AudioManagerHelper.getInstance().playSuccessSound();
            RewardSuccessDialog dialog = new RewardSuccessDialog();
            dialog.show(getParentFragmentManager(), "RewardDialog");
        });

        binding.btnChoiceRabbit.setOnClickListener(v -> showFeedback());
        binding.btnChoiceCow.setOnClickListener(v -> showFeedback());
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
