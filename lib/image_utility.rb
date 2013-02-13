# Common image utilities.
module ImageUtility

  # Resize an image to a height and width.
  # If maintain_aspect_ratio (default true) is set the constraining value
  # is used when resizing the image (i.e. the largest side will match the smallest dimension)
  # otherwise the image will be resized to match the width and height.  expand_to_fit will
  # stretch the image to be at least as big as the height and width.
  # Returns an image.
  def self.resize(image, width, height, maintain_aspect_ratio=true, expand_to_fit=false)
    unless width.nil? && height.nil?
      if maintain_aspect_ratio && (!width.nil? && !height.nil?) 
        desired_ratio = width.to_f / height
        image_ratio = image.columns.to_f / image.rows
        if image_ratio > desired_ratio && !expand_to_fit
          height = nil
        else
          width = nil
        end
      end
      if width.nil?
        width = height * image.columns.to_f / image.rows 
      end
      if height.nil?
        height = width * image.rows.to_f / image.columns
      end
      if image.columns != width && image.rows != height
        image = image.scale(width, height)
      end
    end
    return image
  end

  def self.crop(image, width, height)
    unless width.nil? && height.nil?
      image.crop!(Magick::CenterGravity, width, height)
    end
    return image
  end
end
