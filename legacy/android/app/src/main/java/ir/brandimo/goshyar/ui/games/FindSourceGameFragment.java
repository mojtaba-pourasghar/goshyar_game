package ir.brandimo.goshyar.ui.games;

import ir.brandimo.goshyar.data.GameMode;

/** بازی ۱ — «پیدا کردن منبع صدا»: صدا پخش می‌شود، کودک مکانش را انتخاب می‌کند. */
public class FindSourceGameFragment extends ChoiceGameFragment {
    @Override
    protected String modeId() { return GameMode.FIND_SOURCE; }
}
