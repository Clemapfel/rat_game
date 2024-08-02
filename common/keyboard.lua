--- @class rt.Keyboard
--- @signal accept (rt.Keyboard, String) -> nil
--- @signal cancel (rt.Keyboard) -> nil
--- @signal dont_care (rt.Keyboard) -> String
rt.Keyboard = meta.new_type("Keyboard", rt.Widget, rt.SignalEmitter, function()
    return meta.new(rt.Keyboard, {
        _frame = rt.Frame(),
        _labels = {}, -- Table<Table<rt.Label>>
    })
end)

rt.Keyboard._layout = {
    --[[
    A B C D E F G H I J     À Á Â Ä Ã È É Ê Ë Ẽ
    K L M N O P Q R S T     Ò Ó Ô Ö Õ Ù Ú Û Ü Ũ
    U V W X Y Z             Í Ï Ñ Ç ẞ

    A B C D E F G H I J
    K L M N O P Q R S T
    U V W X Y Z

    a b c d e f g h i j     à á â ä ã è é ê ë ẽ
    k l m n o p q r s t     ò ó ô ö õ ù ú û ü ũ
    u v w x y z             í ï ñ ç ß

    0 1 2 3 4 5 6 7 8 9     . , : ; ! ¡ ? ¿ ( ) + - ~ = " * # / \ < > @ _ ^ ° ' [ ] { } |


    . , : ; " ' ! ? * ^
    + - = ~ | # % $ & _
    < > ( ) [ ] { } / \

    {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", " ", " ", "À", "Á", "Â", "Ä", "Ã", "È", "É", "Ê", "Ë", "Ẽ"},
    {"K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", " ", " ", "Ò", "Ó", "Ô", "Ö", "Õ", "Ù", "Ú", "Û", "Ü", "Ũ"},
    {"U", "V", "W", "X", "Y", "Z", " ", " ", " ", " ", " ", " ", "Í", "Ï", "Ñ", "Ç"},

    ]]--
    {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", " ", " ", ".", ",", ":", ";", "\"", "'", "!", "?", "*", "^"},
    {"K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", " ", " ", "+", "-", "=", "~", "\\|", "#", "%", "$", "&", "_"},
    {"U", "V", "W", "X", "Y", "Z", " ", " ", " ", " ", " ", " ", "\\<", "\\>", "(", ")", "[", "]", "{", "}", "/", "\\\\"},
    {},
    {"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", " ", " ", "à", "á", "â", "ä", "ã", "è", "é", "ê", "ë", "ẽ"},
    {"k", "l", "m", "n", "o", "p", "q", "r", "s", "t", " ", " ", "ò", "ó", "ô", "ö", "õ", "ù", "ú", "û", "ü", "ũ"},
    {"u", "v", "w", "x", "y", "z", " ", " ", " ", " ", " ", " ", "í", "ï", "ñ", "ç", "ß"},
    {},
    {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", " ", " ", "Á", "À", "Ä", "É", "È", "Ó", "Ò", "Ö", "Ù", "Ú", "Ü", "Ñ"},
}

--- @override
function rt.Keyboard:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self._frame:realize()

    self._labels = {}

    local max_row_n = NEGATIVE_INFINITY
    local row_i_to_row_n = {}
    for row_i, row in ipairs(self._layout) do
        local n = sizeof(row)
        row_i_to_row_n[row_i] = row
        max_row_n = math.max(max_row_n, n)
    end

    local font, font_mono = rt.settings.font.default, rt.settings.font.default_mono

    self._labels = {}
    self._max_label_w = NEGATIVE_INFINITY
    self._max_label_h = NEGATIVE_INFINITY
    for row_i, row in ipairs(self._layout) do
        local to_push = {}
        for i = 1, max_row_n do
            local char = self._layout[row_i][i]
            if char == nil then
                char = " "
            end

            local label = rt.Label(char)
            label:set_justify_mode(rt.JustifyMode.CENTER, font, font_mono)
            label:realize()

            local label_w, label_h = label:measure()
            self._max_label_w = math.max(label_w, self._max_label_w)
            self._max_label_h = math.max(label_h, self._max_label_h)

            table.insert(to_push, label)
        end
        table.insert(self._labels, to_push)
    end

    do
        local label = rt.Label(" ")
        label:realize()
        self._max_label_w = select(1, label:measure())
    end
end

--- @override
function rt.Keyboard:size_allocate(x, y, width, height)
    local m = rt.settings.margin_unit
    local xm, ym = 4 * m, 2 * m

    local max_x = NEGATIVE_INFINITY
    local start_x, start_y = xm, ym
    local current_x, current_y = start_x, start_y

    local label_w, label_h = math.max(self._max_label_w, self._max_label_h) + m, self._max_label_h

    for row in values(self._labels) do
        for label in values(row) do
            label:fit_into(current_x, current_y, label_w)
            current_x = current_x + label_w
        end
        current_y = current_y + label_h
        max_x = math.max(max_x, current_x)
        current_x = start_x
    end

    self._frame:fit_into(x, y, max_x - start_x + 2 * xm, current_y - start_y + 2 * ym)
end

--- @override
function rt.Keyboard:draw()
    self._frame:draw()
    for row in values(self._labels) do
        for label in values(row) do
            label:draw()
        end
    end
end