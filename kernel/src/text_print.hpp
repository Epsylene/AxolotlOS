#pragma once

#include "types.hpp"
#include "colors.hpp"

namespace axlt
{
    inline constexpr u32_t VGA_WIDTH = 80;
    inline constexpr u32_t VGA_HEIGHT = 25;
    inline u8_t* const VGA_MEMORY = (u8_t*)0xb8000;

    void clear(u64_t color = BGD_BLACK | FGD_WHITE);

    void set_cursor_pos(u16_t position);
    void set_cursor_pos(u8_t x, u8_t y);

    template<typename T>
    const char* hex_to_string(T value);

    void print(const char* str, u8_t color = BGD_BLACK | FGD_WHITE);
    void print(u32_t value, u8_t color = BGD_BLACK | FGD_WHITE);
}