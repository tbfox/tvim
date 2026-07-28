vim.filetype.add({
    extension = {
        tmux = 'tmux',
        luacov = 'luacov',
    },
    pattern = {
        ['%.env.*'] = 'sh',
        ['.*/%.env%..*'] = 'sh',
    }
})
