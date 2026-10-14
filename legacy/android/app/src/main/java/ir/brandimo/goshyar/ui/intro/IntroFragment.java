package ir.brandimo.goshyar.ui.intro;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import ir.brandimo.goshyar.MainActivity;
import ir.brandimo.goshyar.audio.AudioManagerHelper;
import ir.brandimo.goshyar.databinding.FragmentIntroBinding;
import ir.brandimo.goshyar.ui.menu.MainMenuFragment;
import ir.brandimo.goshyar.ui.views.MascotView;

public class IntroFragment extends Fragment {

    private FragmentIntroBinding binding;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        binding = FragmentIntroBinding.inflate(inflater, container, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        binding.mascotIntro.setPose(MascotView.Pose.ENCOURAGING);

        // Play friendly greeting tone
        AudioManagerHelper.getInstance().playTone(440, 300);

        binding.btnIntroGo.setOnClickListener(v -> {
            if (getActivity() instanceof MainActivity) {
                MainActivity mainActivity = (MainActivity) getActivity();
                mainActivity.setBottomNavVisible(true);
                mainActivity.replaceFragment(new MainMenuFragment());
            }
        });
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        binding = null;
    }
}
