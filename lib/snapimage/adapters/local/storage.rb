module SnapImage
  module Local
    class Storage
      def initialize(config)
        @config = config
        @directory = config["directory"]
        @public_url = config["public_url"]
      end

      # Stores the file in the given directory and returns the publicly
      # accessible URL.
      # Options:
      # * directory - directory to store the file in
      def store(filename, file, options = {})
        file_directory = File.join(@directory, options[:directory])
        file_path = get_file_path(file_directory, filename)
        # Make sure the directory exists.
        FileUtils.mkdir_p(file_directory)
        # Save the file.
        File.open(file_path, "wb") { |f| f.write(file.read) } unless File.exists?(file_path)
        # Return the public URL.
        File.join(@public_url, options[:directory], File.basename(file_path))
      end

      private

      # Gets the file path from the given directory and filename.
      # If the file path already exists, appends a (1) to the basename.
      # If there are already multiple files, appends the next (num) in the
      # sequence.
      def get_file_path(directory, filename)
        file_path = File.join(directory, filename)
        if File.exists?(file_path)
          ext = File.extname(filename)
          basename = File.basename(filename, ext)
          files = Dir.glob(File.join(directory, "#{basename}([0-9]*)#{ext}"))
          if files.size == 0
            num = 1
          else
            num = files.map { |f| f.match(/\((\d+)\)/)[1].to_i }.sort.last + 1
          end
          file_path = "#{File.join(directory, basename)}(#{num})#{ext}"
        end
        file_path
       end
    end
  end
end
