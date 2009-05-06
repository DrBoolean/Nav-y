module Navigation
  
  module ViewHelper
    
    def navigation(options={})
      @nav ||= Nav.new(self, options).to_html
    end
    
  end
  
  
  class Nav
    def initialize(template, options={})
      @template = template
      @request  = request.request_uri
      list = YAML.load(File.open("#{RAILS_ROOT}/config/navigation.yml"))
      @sections = list.map{ |key, value| NavSection.new(key, value) }
      @div_id = options[:id] || "navbar"
    end
      
  
    def create_div(html, kind=:main)
      return if html.blank?
      content = content_tag(:ul, html)
      content << content_tag(:div, "", :class => "clear")
      content_tag(:div, content, :id => [@div_id, kind.to_s].join('_'))
    end
  
  
    def create_list(sections)
      sections.map{ |s| content_tag(:li, link_to(s.name, send(s.link.path)), :class => s.class_name ) } rescue nil
    end
  
  
    def current_section
      @sections.detect{ |s| s.current = s.child_links.any?{ |l| set_current(l) } } || default_section # default to first
    end
    
    
    def default_section
      @sections.first.current = true ; @sections.first
    end
    
    
    def set_current(link)
      link.current = !@request.scan(ActionController::Routing::Routes.recognize_path(send(link.path))[:controller]).empty?
    end

  
    def to_html
      @section = current_section
      @subsections = @section.subsections
      [create_div(create_list(@sections)), create_div(create_list(@subsections), :sub)].compact
    end
    
  
    def method_missing(*args, &block)
      @template.send(*args, &block)
    end
  end


  class NavSection
    attr_accessor :current, :name, :links, :subsections
    alias :current? :current
    
    def initialize(name, links)
      @name = name.titleize
      
      if links.any?{ |link| link.is_a?(Array) }
        @subsections = links.map{ |key, value| SubSection.new(key, value) }
      else
        @links = links.map { |link| NavLink.new(link) }
      end
    end
    
        
    def child_links
      @subsections.map(&:links).flatten rescue self.links
    end
    
    
    def class_name
      'here' if current?
    end
  
  
    def link
      @subsections ? @subsections.first.link : @links.first
    end
  end


  class SubSection < NavSection
    def current?
      @links.any?(&:current)
    end
  
    def link
      @links.first
    end
  end


  class NavLink
    attr_accessor :current, :path
  
    def initialize(path)
      @path = path
    end
  end
end
