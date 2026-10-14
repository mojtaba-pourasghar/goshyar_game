package ir.brandimo.goshyar.ui.games;

import ir.brandimo.goshyar.data.GameMode;

/** بازی ۲ — «این صدا مال کیه؟»: صدا پخش می‌شود، کودک صاحب صدا را انتخاب می‌کند. */
public class WhoMadeSoundGameFragment extends ChoiceGameFragment {
    @Override
    protected String modeId() { return GameMode.WHO_MADE_SOUND; }
}
