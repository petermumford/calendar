module CalendarHelper

  def calendar_links(options)
    links_date = options[:date] || Date.today
    links_view = options[:view] || "monthly"
    start_date = options[:start_date] || :monday

    content_tag(:div, class: "calNav clearfix") do
      content_tag(:div, content_tag(:span, date_title(links_view, start_date, links_date)), class: "month") +
      content_tag(:div, class: "nav_items") do
        content_tag(:div, class: "view-types") do
          link_to(url_for(cal_view_type: links_view, date: link_dates(links_view, links_date, "previous")), class: 'previous') do
            "&nbsp;#{content_tag(:i, '&#x25C5;'.html_safe, class: "ss-icon")}".html_safe
          end +
          link_to("Day", url_for(cal_view_type: "dayly"), class: current_view_type?(links_view, "dayly")) +
          link_to("Week", url_for(cal_view_type: "weekly"), class: current_view_type?(links_view, "weekly")) +
          link_to("Month", url_for(cal_view_type: "monthly"), class: current_view_type?(links_view, "monthly")) +
          link_to("Year", url_for(cal_view_type: "yearly"), class: current_view_type?(links_view, "yearly")) +
          link_to(url_for(cal_view_type: links_view, date: link_dates(links_view, links_date, "next")), class: 'next') do
            "&nbsp;#{content_tag(:i, '&#x25BB;'.html_safe, class: "ss-icon")}".html_safe
          end
        end +
        if !params[:key]
          add_sub_nav_button_link(new_event_path, 'Add Event')
        end
      end
    end
  end

  def add_sub_nav_button_link(path, text)
    content_tag(:div, class: "new-event") do
      link_to(path, class: "clearfix") do
        content_tag(:div, text, class: "text") +
        content_tag(:div, class: "button") do
          content_tag(:i, '&#x002B;'.html_safe, class: "ss-icon ss-icon-large")
        end
      end
    end
  end

  def year_classes(events_date, date)
      classes = []
      classes << "circle-count" if events_date
      classes << "old-event" if events_date && date < Date.today
      classes.empty? ? nil : classes.join(" ")
  end

  def days_date(selectedDate)
      todayDate = Date.today

      if selectedDate == todayDate
        say = "Today's Events"
      elsif selectedDate == todayDate.tomorrow
        say = "Tomorrow's Events"
      elsif selectedDate == todayDate.yesterday
        say = "Yesterday's Events"
      else
        say = "#{selectedDate.strftime("%d %B")} Events"
      end
  end

  private

    def link_dates(view, date, direction)
      if direction == "previous"
        if view == "dayly"
          date-1
        elsif view == "weekly"
          date-7
        elsif view == "yearly"
          date.prev_year
        else
          date.prev_month
        end
      else
        if view == "dayly"
          date+1
        elsif view == "weekly"
          date+7
        elsif view == "yearly"
          date.next_year
        else
          date.next_month
        end
      end
    end

    def current_view_type?(view, type)
      classes = [ "type" ]
      classes << "current" if view == type
      classes.empty? ? nil : classes.join(" ")
    end

    def date_title(current_view, start_date, the_date)
      if current_view == "dayly"
        date_title = the_date.strftime("%a, %d %B %Y")
      elsif current_view == "weekly"
        date_title = "#{the_date.beginning_of_week(start_date).day} - #{the_date.end_of_week(start_date).day} " + the_date.strftime("%B %Y")
      elsif current_view == "yearly"
        date_title = the_date.strftime("%Y")
      else
        date_title = the_date.strftime("%B %Y")
      end
    end


  def calendar(options, &block)
    Calendar.new(self, options, block).table
  end

  class Calendar < Struct.new(:view, :options, :callback)
    include Rails.application.routes.url_helpers
    HEADER = %w[Mon Tue Wed Thu Fri Sat Sun]
    START_DAY = :monday

    delegate :content_tag, :link_to, :url_for, to: :view # expose :content_tag object within this module and apply it to the current view, http://apidock.com/rails/Module/delegate


    def table
      content_tag :table, class: "calendar #{options[:view]}" do
        if options[:view] == "dayly"
          # day_header + day_row
          day_row
        elsif options[:view] == "yearly"
          yearly_view
        else
          header(nil) + week_row(nil)
        end
      end
    end

    def yearly_view
      content_tag :tr do
        content_tag :td, :class => 'for-ie' do
          (0..11).to_a.map { |month_offset|
            content_tag :table, :class => 'year' do
              year_month(month_offset) + content_tag(:tr, header(month_offset)) + week_row(month_offset)
            end
          }.join.html_safe
        end
      end
    end

    def year_month(index)
      content_tag :th, class: ("current-month" if (index+1) == Date.today.month), :colspan => "7" do
        month_name = Date::MONTHNAMES[(index+1)]
        link_to(month_name.html_safe, url_for(:cal_view_type => "monthly", :date => Date.parse("#{options[:date].year}/#{index+1}/01")))
      end
    end

    def header(month)
      HEADER.map.with_index { |day, i|
        content_tag :th, class: header_classes(day, month) do
          if options[:view] == "weekly"
            the_date = options[:date].beginning_of_week(START_DAY) + i
            "#{content_tag(:div, day, :class => 'pull-left')} #{content_tag(:span, sprintf('%02d', the_date.day))}".html_safe
          elsif options[:view] == "yearly"
            "#{content_tag(:table, content_tag(:tr, content_tag(:td, day)), :class => 'day_header')}".html_safe
          else
            day
          end
        end
      }.join.html_safe
    end

    def day_header
      content_tag(:th, class: header_classes(options[:date].strftime("%a"), nil)) do
          daysDate = options[:date].beginning_of_week(START_DAY).day
          "#{content_tag(:span, days_date)}".html_safe
      end
    end

    def day_row
      content_tag(:tr) do
        day_cell(options[:date])
      end
    end

    def week_row(month)
      weeks_in_month = weeks(month)
      weeks_in_month.map do |week|
        content_tag :tr do
          week.map { |day| day_cell(day) }.join.html_safe
        end
      end.join.html_safe +
      if options[:view] == "yearly" && weeks_in_month.count == 5
        content_tag(:td, class: 'empty-row', :colspan => '7') do
          '&nbsp;'.html_safe
        end.html_safe
      end
    end

    def day_cell(day)
      content_tag :td, class: day_classes(day), :data => {date: day} do
        content_tag :div, class: "cell" do
          view.capture(day, &callback)
        end
      end
    end

    def weeks(month)
      if options[:view] == "weekly"
        first = options[:date].beginning_of_week(START_DAY)
        last = options[:date].end_of_week(START_DAY)
      elsif options[:view] == "yearly" && month.present?
        the_month_date = Date.parse("#{options[:date].year}/#{month+1}/#{options[:date].day}")
        first = the_month_date.beginning_of_month.beginning_of_week(START_DAY)
        last = the_month_date.end_of_month.end_of_week(START_DAY)
      else
        first = options[:date].beginning_of_month.beginning_of_week(START_DAY)
        last = options[:date].end_of_month.end_of_week(START_DAY)
      end

      (first..last).to_a.in_groups_of(7)
    end

    # def days_date
    #   todayDate = Date.today
    #   selectedDate = options[:date]

    #   if selectedDate == todayDate
    #     say = "Today's Events"
    #   elsif selectedDate == todayDate.tomorrow
    #     say = "Tomorrow's Events"
    #   elsif selectedDate == todayDate.yesterday
    #     say = "Yesterday's Events"
    #   else
    #     say = "#{selectedDate.strftime("%d %B")} Events"
    #   end
    # end

    def weekday?(day)
      (1..5).include?(day.wday)
    end

    def header_classes(day, month)
      classes = []
      classes << "today" if day == options[:date].strftime("%a") && options[:date] == Date.today if options[:view] == "weekly"
      classes << "months" if options[:view] == "yearly"
      classes << "current-month-day" if options[:view] == "yearly" && (month+1) == Date.today.month
      classes.empty? ? nil : classes.join(" ")
    end

    def day_classes(day)
      classes = []
      classes << "withHover" if day >= Date.today && options[:view] == "monthly"
      classes << "today" if day == Date.today && options[:view] == "monthly"
      classes << "weekly-past" if day < Date.today && options[:view] == "weekly"
      classes << "weekly-default" if day >= Date.today && options[:view] == "weekly"
      # classes << "weekend" if !weekday?(day)
      classes << "past" if day < Date.today && options[:view] == "monthly"
      classes << "notmonth" if day.month != options[:date].month
      classes.empty? ? nil : classes.join(" ")
    end

  end

end
