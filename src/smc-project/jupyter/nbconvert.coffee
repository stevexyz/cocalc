###
Node.js interface to nbconvert.
###

misc = require('smc-util/misc')
{defaults, required} = misc

misc_node = require('smc-util-node/misc_node')

exports.nbconvert = (opts) ->
    opts = defaults opts,
        args      : required
        directory : undefined
        timeout   : 30
        cb        : required
    misc_node.execute_code
        command     : 'jupyter'
        args        : ['nbconvert'].concat(opts.args)
        path        : opts.directory
        err_on_exit : true
        timeout     : opts.timeout   # in seconds
        cb          : (err, output) =>
            if err and output?.stderr
                err = output?.stderr
            opts.cb(err)