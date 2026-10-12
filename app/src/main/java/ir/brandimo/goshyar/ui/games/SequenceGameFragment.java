package ir.brandimo.goshyar.ui.games;

import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import ir.brandimo.goshyar.audio.AudioManagerHelper;
import ir.brandimo.goshyar.databinding.FragmentGameSequenceBinding;
import ir.brandimo.goshyar.ui.dialogs.RewardSuccessDialog;

public class SequenceGameFragment extends Fragment {

    private FragmentGameSequenceBinding binding;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        binding = FragmentGameSequenceBinding.inflate(inflater, container, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        binding.btnPlaySequence.setOnClickListener(v -> {
            AudioManagerHelper.getInstance().playTone(400, 200);
            new Handler(Looper.getMainLooper()).postDelayed(() -> AudioManagerHelper.getInstance().playTone(600, 200), 300);
            new Handler(Looper.getMainLooper()).postDelayed(() -> AudioManagerHelper.getInstance().playTone(800, 200), 600);
        });

        binding.btnVerifySequence.setOnClickListener(v -> {
            AudioManagerHelper.getInstance().playSuccessSound();
            RewardSuccessDialog dialog = new RewardSuccessDialog();
            dialog.show(getParentFragmentManager(), "RewardDialog");
        });
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        binding = null;
    }
}
