package ir.brandimo.goshyar.ui.offline;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import ir.brandimo.goshyar.R;
import ir.brandimo.goshyar.audio.AudioManagerHelper;
import ir.brandimo.goshyar.data.GameContent;
import ir.brandimo.goshyar.data.SoundItem;
import ir.brandimo.goshyar.databinding.FragmentOfflineModeBinding;

/**
 * حالت آفلاین. محتوای صوتی داخل خود بسته برنامه است، پس اینجا فقط
 * وضعیت واقعی فایل‌های موجود گزارش می‌شود — نه یک پیام تزئینی.
 */
public class OfflineModeFragment extends Fragment {

    private FragmentOfflineModeBinding binding;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        binding = FragmentOfflineModeBinding.inflate(inflater, container, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        binding.btnCheckOffline.setOnClickListener(v -> showStatus());
        showStatus();
    }

    private void showStatus() {
        GameContent content = GameContent.get(requireContext());
        AudioManagerHelper audio = AudioManagerHelper.getInstance();

        int have = 0, total = 0;
        for (var mode : content.allModes()) {
            for (var level : mode.levels) {
                for (String id : allSoundIds(level)) {
                    SoundItem s = content.sound(id);
                    if (s == null) continue;
                    total++;
                    if (audio.exists(s.audioPath)) have++;
                }
            }
        }
        binding.tvOfflineStatus.setText(getString(R.string.offline_status, have, total));
        binding.progressOffline.setMax(Math.max(1, total));
        binding.progressOffline.setProgress(have);
    }

    private java.util.List<String> allSoundIds(ir.brandimo.goshyar.data.GameLevel l) {
        java.util.List<String> ids = new java.util.ArrayList<>();
        if (l.soundId != null && !l.soundId.isEmpty()) ids.add(l.soundId);
        ids.addAll(l.sequence);
        ids.addAll(l.layers);
        return ids;
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        binding = null;
    }
}
