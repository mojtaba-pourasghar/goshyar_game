package ir.brandimo.goshyar.ui.settings;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import ir.brandimo.goshyar.MainActivity;
import ir.brandimo.goshyar.R;
import ir.brandimo.goshyar.audio.AudioManagerHelper;
import ir.brandimo.goshyar.data.ProgressStore;
import ir.brandimo.goshyar.databinding.FragmentSettingsBinding;
import ir.brandimo.goshyar.ui.offline.OfflineModeFragment;

/** تنظیمات صدا و گوینده. وضعیت کلیدها از روی مقدار ذخیره‌شده خوانده می‌شود. */
public class SettingsFragment extends Fragment {

    private FragmentSettingsBinding binding;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        binding = FragmentSettingsBinding.inflate(inflater, container, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        AudioManagerHelper audio = AudioManagerHelper.getInstance();

        binding.switchBgMusic.setChecked(audio.isMusicEnabled());
        binding.switchSfx.setChecked(audio.isSfxEnabled());
        binding.switchNarrator.setChecked(audio.isVoiceEnabled());

        binding.switchBgMusic.setOnCheckedChangeListener((b, on) -> audio.setMusicEnabled(on));
        binding.switchSfx.setOnCheckedChangeListener((b, on) -> audio.setSfxEnabled(on));
        binding.switchNarrator.setOnCheckedChangeListener((b, on) -> audio.setVoiceEnabled(on));

        binding.btnOfflineModeScreen.setOnClickListener(v -> navigate(new OfflineModeFragment()));

        binding.btnResetProgress.setOnClickListener(v -> {
            ProgressStore.get(requireContext()).reset();
            Toast.makeText(getContext(), R.string.progress_reset_done, Toast.LENGTH_SHORT).show();
        });

        binding.btnSettingsBack.setOnClickListener(v -> requireActivity()
                .getOnBackPressedDispatcher().onBackPressed());
    }

    private void navigate(Fragment f) {
        if (getActivity() instanceof MainActivity) ((MainActivity) getActivity()).replaceFragment(f);
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        binding = null;
    }
}
