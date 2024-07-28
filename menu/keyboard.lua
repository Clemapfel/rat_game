--[[

A B C D E F G H I J
K L M N O P Q R S T
U V W X Y Z

a b c d e f g h i j
k l m n o p q r s t
u v w x y z

0 1 2 3 4 5 6 7 8 9

à á â ä ã è é ê ë ẽ
ò ó ô ö õ ù ú û ü ũ
í ï ñ ç ß

À Á Â Ä Ã È É Ê Ë Ẽ
Ò Ó Ô Ö Õ Ù Ú Û Ü Ũ
Í Ï Ñ Ç ẞ

. , : ; ! ¡ ? ¿ ( )

A B C D E F G H I J     À Á Â Ä Ã È É Ê Ë Ẽ
K L M N O P Q R S T     Ò Ó Ô Ö Õ Ù Ú Û Ü Ũ
U V W X Y Z             Í Ï Ñ Ç ẞ

a b c d e f g h i j     à á â ä ã è é ê ë ẽ
k l m n o p q r s t     ò ó ô ö õ ù ú û ü ũ
u v w x y z             í ï ñ ç ß

0 1 2 3 4 5 6 7 8 9     . , : ; ! ¡ ? ¿ ( )
]]--

mn.Keyboard = meta.new_type("MenuKeyboard", rt.Widget, function()
    return meta.new(mn.Keyboard, {
        _items = {}
    })
end, {
    layout = {
        {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", " ", " ", "À", "Á", "Â", "Ä", "Ã", "È", "É", "Ê", "Ë", "Ẽ"},
        {"K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", " ", " ", "Ò", "Ó", "Ô", "Ö", "Õ", "Ù", "Ú", "Û", "Ü", "Ũ"},
        {"U", "V", "W", "X", "Y", "Z", " ", " ", " ", " ", " ", " ", "Í", "Ï", "Ñ", "Ç", "ẞ"},
        {},
        {"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", " ", " ", "à", "á", "â", "ä", "ã", "è", "é", "ê", "ë", "ẽ"},
        {"k", "l", "m", "n", "o", "p", "q", "r", "s", "t", " ", " ", "ò", "ó", "ô", "ö", "õ", "ù", "ú", "û", "ü", "ũ"},
        {"u", "v", "w", "x", "y", "z", " ", " ", " ", " ", " ", " ", "í", "ï", "ñ", "ç", "ß"},
        {},
        {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", " ", " ", ".", ",", ":", ";", "!", "¡", "?", "¿", "(", ")"}
    }
})

--- @override
function mn.Keyboard:realize()
    self._is_realized = true

    local max_row_size = NEGATIVE_INFINITY
    for row in values(self.layout) do
        max_row_size = math.max(max_row_size, #row)
    end

    local font = rt.settings.font.default
    for layout_row in values(self.layout) do
        local row = {}
        for i = 1, max_row_size do
            local char = row[i]
            if char == nil then char = "  " end
            table.insert(row, {
                label = rt.Label("<b>" .. char .. "</b>", font),
                frame = rt.Frame()
            })
        end

        for item in values(row) do
            item.label:realize()
            item.frame:realize()

            item.frame:set_color(rt.Palette.GRAY_3)
        end
    end
end

--- @override