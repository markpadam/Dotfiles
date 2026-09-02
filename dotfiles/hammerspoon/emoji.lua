-- emoji.lua — an emoji / Nerd-Font-glyph picker for the Opt+Space menu
-- (Walker's emoji + symbols modules). Pick one and it's typed into the
-- frontmost field. menu.lua's own filter searches the keyword-laden names.

local M = {}

local function typer(s)
  return function() hs.timer.doAfter(0.12, function() hs.eventtap.keyStrokes(s) end) end
end

-- name doubles as the search haystack — pack it with keywords
local EMOJI = {
  { "😀 grinning happy smile" }, { "😁 beaming grin happy" }, { "😂 joy laugh tears lol" },
  { "🤣 rofl rolling laughing" }, { "😊 blush smile happy" }, { "🙂 slight smile" },
  { "😉 wink" }, { "😍 heart eyes love" }, { "😘 kiss blow" }, { "😎 cool sunglasses" },
  { "🤩 star struck excited" }, { "🥳 party celebrate" }, { "🤔 thinking hmm" },
  { "🤨 raised eyebrow skeptical" }, { "😐 neutral meh" }, { "😑 expressionless" },
  { "🙄 eye roll" }, { "😏 smirk" }, { "😒 unamused" }, { "😞 disappointed sad" },
  { "😔 pensive sad" }, { "😢 cry sad tear" }, { "😭 sob crying loud" },
  { "😤 triumph steam" }, { "😠 angry" }, { "😡 rage mad furious" }, { "🤯 mind blown" },
  { "😳 flushed shocked" }, { "🥵 hot heat" }, { "🥶 cold freezing" }, { "😱 scream fear" },
  { "😨 fearful anxious" }, { "😰 anxious sweat" }, { "😥 sad relieved" }, { "🤗 hug hugging" },
  { "🤫 shush quiet" }, { "🤭 giggle oops" }, { "😴 sleep zzz" }, { "🤤 drool" },
  { "😷 mask sick" }, { "🤒 sick thermometer" }, { "🤕 hurt bandage" }, { "🤢 nausea sick" },
  { "🤮 vomit puke" }, { "🥴 woozy dizzy" }, { "😵 dizzy dead" }, { "🤠 cowboy" },
  { "🥸 disguise" }, { "😇 innocent halo angel" }, { "🫠 melting" }, { "👻 ghost boo" },
  { "💀 skull dead" }, { "☠️ skull crossbones danger" }, { "👽 alien ufo" },
  { "🤖 robot bot" }, { "💩 poop crap" }, { "🎃 pumpkin halloween" }, { "😺 cat smile" },
  { "🙈 see no evil monkey" }, { "🙉 hear no evil monkey" }, { "🙊 speak no evil monkey" },
  { "👍 thumbs up yes approve like" }, { "👎 thumbs down no disapprove" },
  { "👌 ok perfect" }, { "🤌 pinch italian" }, { "✌️ peace victory" }, { "🤞 fingers crossed luck" },
  { "🤟 love you ily" }, { "🤘 rock horns" }, { "🤙 call me shaka" }, { "👈 point left" },
  { "👉 point right" }, { "👆 point up" }, { "👇 point down" }, { "☝️ index up" },
  { "✋ raised hand stop" }, { "🤚 back hand" }, { "🖐️ hand splayed" }, { "🖖 vulcan spock" },
  { "👋 wave hello hi bye" }, { "🤝 handshake deal" }, { "🙏 pray thanks please namaste" },
  { "✊ fist raised" }, { "👊 fist bump punch" }, { "🫶 heart hands" }, { "💪 muscle strong flex" },
  { "🦾 mechanical arm" }, { "👏 clap applause bravo" }, { "🙌 raised hands praise celebrate" },
  { "👐 open hands" }, { "🤲 palms up" }, { "🫡 salute yes sir" }, { "🤦 facepalm" },
  { "🤷 shrug idk whatever" }, { "❤️ red heart love" }, { "🧡 orange heart" },
  { "💛 yellow heart" }, { "💚 green heart" }, { "💙 blue heart" }, { "💜 purple heart" },
  { "🖤 black heart" }, { "🤍 white heart" }, { "💔 broken heart" }, { "❣️ heart exclamation" },
  { "💕 two hearts" }, { "💞 revolving hearts" }, { "💓 beating heart" }, { "💗 growing heart" },
  { "💖 sparkling heart" }, { "💘 heart arrow cupid" }, { "💝 heart gift" }, { "💯 hundred perfect keep it" },
  { "💢 anger symbol" }, { "💥 boom collision explode" }, { "💫 dizzy stars" }, { "💦 sweat drops splash" },
  { "💨 dash wind fast" }, { "🕳️ hole" }, { "💬 speech bubble comment" }, { "💭 thought bubble" },
  { "🔥 fire lit hot flame" }, { "⭐ star" }, { "🌟 glowing star" }, { "✨ sparkles shiny magic" },
  { "⚡ zap lightning bolt fast" }, { "☀️ sun sunny" }, { "🌙 moon night crescent" },
  { "🌈 rainbow pride" }, { "☁️ cloud" }, { "⛅ partly cloudy" }, { "🌧️ rain" }, { "⛈️ storm thunder" },
  { "❄️ snowflake cold winter" }, { "☃️ snowman" }, { "💧 droplet water" }, { "🌊 wave ocean water" },
  { "✅ check tick done yes complete" }, { "❌ cross x no wrong fail" }, { "❎ cross button" },
  { "➕ plus add" }, { "➖ minus subtract" }, { "➗ divide" }, { "✖️ multiply" },
  { "❓ question" }, { "❗ exclamation bang" }, { "‼️ double exclamation" }, { "⚠️ warning caution" },
  { "🚫 no forbidden prohibited" }, { "🔴 red circle" }, { "🟢 green circle" }, { "🟡 yellow circle" },
  { "🔵 blue circle" }, { "⚪ white circle" }, { "⚫ black circle" }, { "🟠 orange circle" },
  { "🟣 purple circle" }, { "🔺 red triangle up" }, { "🔻 red triangle down" },
  { "🔒 lock locked secure" }, { "🔓 unlock open" }, { "🔑 key" }, { "🗝️ old key" },
  { "🔗 link chain" }, { "📎 paperclip attach" }, { "📌 pushpin pin" }, { "📍 round pin location" },
  { "🎯 target dart bullseye goal" }, { "🚀 rocket launch ship deploy fast" }, { "🛸 ufo" },
  { "💡 idea bulb light" }, { "🔦 flashlight torch" }, { "🔋 battery" }, { "🔌 plug power" },
  { "💻 laptop computer" }, { "🖥️ desktop monitor" }, { "⌨️ keyboard" }, { "🖱️ mouse" },
  { "💾 floppy save disk" }, { "💿 cd disc" }, { "📀 dvd" }, { "🖨️ printer" }, { "📱 phone mobile" },
  { "📞 phone call" }, { "📸 camera photo" }, { "🎥 movie camera film" }, { "🎬 clapper action" },
  { "🔍 magnify search zoom find" }, { "🔎 magnify right search" }, { "🔬 microscope science" },
  { "🔭 telescope" }, { "📡 satellite antenna signal" }, { "⏰ alarm clock" }, { "⏱️ stopwatch timer" },
  { "⏳ hourglass loading wait" }, { "⌛ hourglass done" }, { "📅 calendar date" }, { "📆 tear off calendar" },
  { "📈 chart up growth increase" }, { "📉 chart down decrease loss" }, { "📊 bar chart stats" },
  { "🗂️ card index dividers" }, { "📁 folder" }, { "📂 open folder" }, { "🗃️ file box" },
  { "📝 memo note write pencil" }, { "✏️ pencil" }, { "✒️ black nib pen" }, { "🖊️ pen" }, { "🖍️ crayon" },
  { "📖 open book read docs" }, { "📚 books library" }, { "🔖 bookmark" }, { "🏷️ label tag" },
  { "💰 money bag" }, { "💵 dollar cash" }, { "💳 credit card payment" }, { "🧾 receipt" },
  { "🎁 gift present" }, { "🎉 tada party celebrate" }, { "🎊 confetti ball" }, { "🎈 balloon" },
  { "🏆 trophy win champion" }, { "🥇 gold medal first" }, { "🥈 silver medal second" }, { "🥉 bronze medal third" },
  { "🏅 medal" }, { "🎖️ military medal" }, { "🎗️ ribbon" }, { "🔮 crystal ball magic future" },
  { "🧿 nazar amulet" }, { "🎮 game controller" }, { "🕹️ joystick" }, { "🎲 dice game random" },
  { "🧩 puzzle piece" }, { "♟️ chess pawn" }, { "🎨 art palette paint design" }, { "🖌️ paintbrush" },
  { "🧵 thread" }, { "🪡 needle" }, { "🎵 music note" }, { "🎶 musical notes" }, { "🎤 mic sing karaoke" },
  { "🎧 headphones listen" }, { "🥁 drum" }, { "🎸 guitar" }, { "🎹 piano keyboard music" },
  { "☕ coffee tea hot drink" }, { "🍵 tea green" }, { "🍺 beer" }, { "🍻 beers cheers" },
  { "🥂 champagne toast cheers" }, { "🍷 wine" }, { "🥃 whisky tumbler" }, { "🍸 cocktail martini" },
  { "🍕 pizza" }, { "🍔 burger" }, { "🍟 fries" }, { "🌮 taco" }, { "🌯 burrito" }, { "🍣 sushi" },
  { "🍜 ramen noodles" }, { "🍩 donut" }, { "🍪 cookie" }, { "🎂 birthday cake" }, { "🍰 cake slice" },
  { "🍫 chocolate" }, { "🍿 popcorn" }, { "🧊 ice cube" }, { "🍎 apple" }, { "🍌 banana" },
  { "🍓 strawberry" }, { "🍇 grapes" }, { "🍉 watermelon" }, { "🥑 avocado" }, { "🌶️ chili pepper spicy" },
  { "🐶 dog puppy" }, { "🐱 cat kitten" }, { "🐭 mouse" }, { "🦊 fox" }, { "🐻 bear" }, { "🐼 panda" },
  { "🐨 koala" }, { "🦁 lion" }, { "🐯 tiger" }, { "🐸 frog" }, { "🐵 monkey" }, { "🐔 chicken" },
  { "🐧 penguin" }, { "🐦 bird" }, { "🦆 duck" }, { "🦉 owl" }, { "🦄 unicorn" }, { "🐝 bee" },
  { "🐛 bug caterpillar" }, { "🦋 butterfly" }, { "🐢 turtle slow" }, { "🐍 snake" }, { "🐙 octopus" },
  { "🦈 shark" }, { "🐳 whale" }, { "🐬 dolphin" }, { "🐟 fish" }, { "🦀 crab" }, { "🌵 cactus" },
  { "🌲 evergreen tree" }, { "🌳 tree" }, { "🌴 palm tree" }, { "🌱 seedling sprout" }, { "🌿 herb leaf" },
  { "☘️ shamrock clover" }, { "🍀 four leaf clover luck" }, { "🍁 maple leaf" }, { "🍂 fallen leaves autumn" },
  { "🌷 tulip" }, { "🌹 rose" }, { "🌸 cherry blossom" }, { "🌻 sunflower" }, { "🌼 blossom flower" },
  { "💐 bouquet flowers" }, { "🌍 earth globe world" }, { "🗺️ map world" }, { "🧭 compass" },
  { "🏔️ mountain snow" }, { "🌋 volcano" }, { "🏕️ camping tent" }, { "🏖️ beach" }, { "🏝️ desert island" },
  { "🚗 car" }, { "🚕 taxi" }, { "🚙 suv" }, { "🚌 bus" }, { "🚓 police car" }, { "🚑 ambulance" },
  { "🚒 fire truck" }, { "🚚 truck delivery" }, { "🚲 bike bicycle" }, { "🛴 scooter" }, { "🏍️ motorcycle" },
  { "✈️ plane flight travel" }, { "🚁 helicopter" }, { "🚂 train" }, { "🚆 train fast" }, { "🚇 metro subway" },
  { "⛵ sailboat" }, { "🚢 ship cruise" }, { "⚓ anchor" }, { "🛟 life ring buoy" }, { "🚦 traffic light" },
  { "🗿 moai statue" }, { "🗽 statue of liberty" }, { "🏰 castle" }, { "🏠 house home" }, { "🏢 office building" },
  { "🏥 hospital" }, { "🏦 bank" }, { "🏪 convenience store" }, { "🏫 school" }, { "⛪ church" },
  { "🕌 mosque" }, { "🛕 temple hindu" }, { "🕍 synagogue" }, { "⛩️ shinto shrine" },
}

function M.menu()
  local items = {}
  for _, e in ipairs(EMOJI) do
    local char = e[1]:match("^(%S+)")
    items[#items + 1] = { name = e[1], action = typer(char) }
  end
  return { title = "Emoji", width = 380, items = items }
end

-- Nerd Font glyphs the setup already uses — handy to paste into configs
local GLYPHS = {
  { "\u{f001} music", "\u{f001}" }, { "\u{f008} film", "\u{f008}" },
  { "\u{f011} power", "\u{f011}" }, { "\u{f013} cog gear settings", "\u{f013}" },
  { "\u{f023} lock", "\u{f023}" }, { "\u{f02b} tag", "\u{f02b}" },
  { "\u{f030} camera", "\u{f030}" }, { "\u{f03d} video", "\u{f03d}" },
  { "\u{f07b} folder", "\u{f07b}" }, { "\u{f085} cogs", "\u{f085}" },
  { "\u{f0ac} globe web", "\u{f0ac}" }, { "\u{f0c3} flask", "\u{f0c3}" },
  { "\u{f0e7} bolt zap", "\u{f0e7}" }, { "\u{f0eb} lightbulb idea", "\u{f0eb}" },
  { "\u{f0f3} bell", "\u{f0f3}" }, { "\u{f0f4} coffee", "\u{f0f4}" },
  { "\u{f120} terminal prompt", "\u{f120}" }, { "\u{f121} code", "\u{f121}" },
  { "\u{f126} branch git", "\u{f126}" }, { "\u{f17c} linux tux", "\u{f17c}" },
  { "\u{f179} apple", "\u{f179}" }, { "\u{f188} bug", "\u{f188}" },
  { "\u{f198} slack", "\u{f198}" }, { "\u{f1eb} wifi", "\u{f1eb}" },
  { "\u{f244} battery empty", "\u{f244}" }, { "\u{f240} battery full", "\u{f240}" },
  { "\u{f2d0} window maximize", "\u{f2d0}" }, { "\u{f2d1} window minimize", "\u{f2d1}" },
  { "\u{e62b} vim neovim", "\u{e62b}" }, { "\u{e615} kubernetes", "\u{e615}" },
  { "\u{e627} lua", "\u{e627}" }, { "\u{e60b} nodejs", "\u{e60b}" },
  { "\u{e73c} python", "\u{e73c}" }, { "\u{e7a8} rust", "\u{e7a8}" },
  { "\u{e626} go golang", "\u{e626}" }, { "\u{e7b0} docker", "\u{e7b0}" },
  { "\u{f308} docker whale", "\u{f308}" }, { "\u{ebc8} tmux", "\u{ebc8}" },
  { "\u{f0a0} database disk", "\u{f0a0}" }, { "\u{2318} command mac", "\u{2318}" },
}

function M.glyphMenu()
  local items = {}
  for _, g in ipairs(GLYPHS) do
    items[#items + 1] = { name = g[1], g = g[2], action = typer(g[2]) }
  end
  return { title = "Glyphs", width = 360, items = items }
end

return M
