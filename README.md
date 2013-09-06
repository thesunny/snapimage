# Snapimage

SnapImage is a Rack middleware that supports server-side image uploading for [SnapEditor](http://snapeditor.com), an online HTML5 WYSIWYG text editor. It also provides a self-contained server that is ready to roll.

## Installation

Add this line to your application's Gemfile:

    gem 'snapimage'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install snapimage

## Configuration

Generate a config file (default is "config/snapimage\_config.yml"). SnapImage comes with a script to do that.

    $ snapimage_generate_config <adapter> [options]

For details, use the -h flag.

    $ snapimage_generate_config -h

## Usage

The middleware class is SnapImage::Middleware. It takes the following options.

    path: The URL path that SnapImage listens to and accepts image uploads from (default is "/snapimage_api").
    config: The path to the config file (default is "config/snapimage_config.yml").

### Rails

Add the following to application.rb.

    config.middleware.use SnapImage::Middleware

### Other Rack Applications

Add the following to your server.

    use SnapImage::Middleware

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
