shader_type canvas_item;

// Эта строка позволяет брать картинку экрана ПОЗАДИ панели
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
// Переменная для настройки силы размытия в Инспекторе
uniform float blur_amount : hint_range(0.0, 5.0) = 2.0;

void fragment() {
    // Получаем размытый цвет из текстуры экрана
    vec4 color = textureLod(screen_texture, SCREEN_UV, blur_amount);
    // Применяем его к нашей панели
    COLOR = color;
}
