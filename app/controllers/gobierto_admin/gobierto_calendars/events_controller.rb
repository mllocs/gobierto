module GobiertoAdmin
  module GobiertoCalendars
    class EventsController < BaseController
      before_action :load_collection, :load_person

      def index
        @events_presenter = GobiertoAdmin::GobiertoCalendars::EventsPresenter.new(@collection)
        @events = ::GobiertoCalendars::Event.by_collection(@collection).sorted

        case params[:scope]
        when "pending"
          @events = @events.pending
        when "published"
          @events = @events.published
        when "past"
          @events = @events.past
        end
      end

      def new
        @event_form = EventForm.new(collection_id: @collection.id)
        @attendees = get_attendees
        @event_states = get_calendar_event_states
      end

      def edit
        @event = find_event
        @event_states = get_calendar_event_states
        @attendees = get_attendees

        @event_form = EventForm.new(
          @event.attributes.except(*ignored_event_attributes).merge(collection_id: @collection.id)
        )
      end

      def create
        @event_form = EventForm.new(
          event_params.merge(collection_id: @collection.id, admin_id: current_admin.id, site_id: current_site.id)
        )

        if @event_form.save
          redirect_to(
            edit_admin_calendars_collection_event_path(@collection, @event_form.event),
            notice: t(".success_html", link: gobierto_people_event_preview_url(@event_form.event))
          )
        else
          @attendees = get_attendees
          @event_states = get_calendar_event_states
          render :new
        end
      end

      def update
        @event = find_event
        @event_form = EventForm.new(
          event_params.merge(id: params[:id], admin_id: current_admin.id, site_id: current_site.id, collection_id: @collection.id)
        )

        if @event_form.save
          redirect_to(
            edit_admin_calendars_collection_event_path(@collection, @event),
            notice: t(".success_html", link: gobierto_people_event_preview_url(@event_form.event))
          )
        else
          @attendees = get_attendees
          @event_states = get_calendar_event_states
          render :edit
        end
      end

      private

      def load_collection
        @collection = current_site.collections.find(params[:collection_id])
      end

      def load_person
        if person_collection?
          @person = @collection.container
        end
      end

      def find_event
        current_site.events.find params[:id]
      end

      def get_attendees
        person_id = person_collection? ? @collection.container.id : 0
        current_site.people
          .where.not(id: person_id)
          .active
          .select(:id, :name)
      end

      def person_collection?
        @collection.container.is_a?(::GobiertoPeople::Person)
      end

      def get_calendar_event_states
        ::GobiertoCalendars::Event.states
      end

      def event_params
        params.require(:event).permit(
          :starts_at,
          :ends_at,
          :attachment_file,
          :state,
          locations_attributes: [:id, :name, :address, :lat, :lng, :_destroy],
          attendees_attributes: [:id, :person_id, :name, :charge, :_destroy],
          title_translations: [*I18n.available_locales],
          description_translations: [*I18n.available_locales]
        )
      end

      def ignored_event_attributes
        %w( created_at updated_at title description external_id slug site_id collection_id )
      end
    end
  end
end
