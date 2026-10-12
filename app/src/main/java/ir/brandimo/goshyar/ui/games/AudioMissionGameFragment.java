package ir.brandimo.goshyar.ui.games;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import ir.brandimo.goshyar.audio.AudioManagerHelper;
import ir.brandimo.goshyar.databinding.FragmentGameAudioMissionBinding;
import ir.brandimo.goshyar.ui.dialogs.RewardSuccessDialog;
import ir.brandimo.goshyar.ui.views.MascotView;

public class AudioMissionGameFragment extends Fragment {

    private FragmentGameAudioMissionBinding binding;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        binding = FragmentGameAudioMissionBinding.inflate(inflater, container, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        binding.mascotMission.setPose(MascotView.Pose.LISTENING);

        binding.btnStartMission.setOnClickListener(v -> {
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
