Config = {}

-- Animation settings
Config.Animation = {
    dict = 'script_common@jail_cell@unlock@key',
    clip = 'action',
    duration = 5000 -- 5 seconds to wrap
}

-- Items that CANNOT be wrapped
Config.BlacklistedItems = {
    'present',
    'oldbox',
    'wrapping_paper',
    'gift_tag',
    'dollars',
    'cent'
}


Config.PresentItem = 'present'

Config.EmptyBoxItem = 'oldbox'

Config.WrappingPaperItem = 'wrapping_paper'

Config.GiftTagItem = 'gift_tag'

-- Maximum distance to give present to another player
Config.GiveDistance = 3.0

Config.PresentProp = nil

-- Messages
Config.Messages = {
    wrapping = 'Wrapping present...',
    wrapped_success = 'Present wrapped successfully!',
    wrapped_cancel = 'Wrapping cancelled!',
    no_box = 'You need an empty gift box!',
    no_paper = 'You need wrapping paper!',
    no_materials = 'You need an empty gift box and wrapping paper!',
    no_items = 'You have no items to wrap!',
    blacklisted = 'This item cannot be wrapped!',
    no_players = 'No players nearby!',
    gave_present = 'You gave a present to %s',
    received_present = 'You received a present from %s',
    unwrapped = 'You unwrapped: %s x%s',
    invalid_present = 'This present appears to be empty or damaged!',
    gift_tag_title = '🎄 Gift Tag 🎄',
    gift_tag_message = 'To: %s\nFrom: %s\n\nMerry Christmas! 🎅'
}