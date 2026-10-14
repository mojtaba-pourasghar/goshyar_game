package ir.brandimo.goshyar.ui.parent;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.DialogFragment;

import java.util.Random;

import ir.brandimo.goshyar.MainActivity;
import ir.brandimo.goshyar.R;
import ir.brandimo.goshyar.databinding.DialogParentGateBinding;

/**
 * دروازه والدین: یک جمع تصادفی دو رقمی. چون سؤال تصادفی است،
 * کودک نمی‌تواند جواب را حفظ کند.
 */
public class ParentGateDialog extends DialogFragment {

    private DialogParentGateBinding binding;
    private int expected;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        binding = DialogParentGateBinding.inflate(inflater, container, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        Random r = new Random();
        int a = 11 + r.nextInt(9);   // ۱۱ تا ۱۹
        int b = 11 + r.nextInt(9);
        expected = a + b;
        binding.tvGateQuestion.setText(getString(R.string.parent_gate_question, a, b));

        binding.btnVerifyGate.setOnClickListener(v -> {
            if (parse(binding.etGateAnswer.getText().toString()) == expected) {
                dismiss();
                if (getActivity() instanceof MainActivity) {
                    ((MainActivity) getActivity()).replaceFragment(new ParentDashboardFragment());
                }
            } else {
                Toast.makeText(getContext(), R.string.parent_gate_wrong, Toast.LENGTH_SHORT).show();
                binding.etGateAnswer.setText("");
            }
        });
    }

    /** ارقام فارسی و عربی را هم می‌پذیرد. */
    private static int parse(String raw) {
        StringBuilder sb = new StringBuilder();
        for (char c : raw.trim().toCharArray()) {
            if (c >= '0' && c <= '9') sb.append(c);
            else if (c >= '۰' && c <= '۹') sb.append((char) ('0' + c - '۰'));
            else if (c >= '٠' && c <= '٩') sb.append((char) ('0' + c - '٠'));
        }
        try {
            return Integer.parseInt(sb.toString());
        } catch (NumberFormatException e) {
            return Integer.MIN_VALUE;
        }
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        binding = null;
    }
}
