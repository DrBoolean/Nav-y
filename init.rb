# Include hook code here
require 'navigation'

ActionView::Base.send(:include, Navigation::ViewHelper)
