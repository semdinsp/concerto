class FeedsController < ApplicationController
  rescue_from ActionView::Template::Error, :with => :precompile_error_catch
  respond_to :html, :json
  
  # GET /feeds
  # GET /feeds.xml
  # GET /feeds.js
  def index
    redirect_to(new_user_session_path) unless ConcertoConfig[:public_concerto]
    @feeds = Feed.roots
    auth!
    respond_with(@feeds)
    @active_content = 0
    @feeds.each { |node| node.submissions.each { |submission| if submission.moderation_flag == true then @active_content += 1 end } }
  end

  # GET /moderate
  # GET /moderate.js
  def moderate
    @feeds = Feed.all
    auth!(:object => @feeds, :action => :update, :allow_empty => false)
    @feeds.reject!{|f| not f.pending_contents.count > 0}
    
    respond_to do |format|
      format.html { }
      format.js { }
    end
  end

  # GET /feeds/1
  # GET /feeds/1.xml
  # GET /feeds/1.js
  def show
    @feed = Feed.find(params[:id])
    auth!

    respond_to do |format|
      format.html { redirect_to(feed_submissions_path(@feed)) }
      format.xml  { render :xml => @feed }
      format.js { render :layout => false }
    end
  end

  # GET /feeds/new
  # GET /feeds/new.xml
  def new
    @feed = Feed.new
    auth!
    
    #populate the checkboxes for content types by default when creating a new feed
    Concerto::Application.config.content_types.each do |type|
      @feed.content_types[type.name] = "1"
    end

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @feed }
    end
  end

  # GET /feeds/1/edit
  def edit
    @feed = Feed.find(params[:id])
    auth!
  end

  # POST /feeds
  # POST /feeds.xml
  def create
    @feed = Feed.new(feed_params)
    auth!
    if @feed.save
      process_notification(@feed, {:public_owner => current_user.id}, :action => 'create')
      flash[:notice] = t(:feed_created)
    end
    respond_with(@feed)
  end

  # PUT /feeds/1
  # PUT /feeds/1.xml
  def update
    @feed = Feed.find(params[:id])
    auth!

    respond_to do |format|
      if @feed.update_attributes(feed_params)
        format.html { redirect_to(feed_submissions_path(@feed), :notice => t(:feed_updated)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @feed.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /feeds/1
  # DELETE /feeds/1.xml
  def destroy
    @feed = Feed.find(params[:id])
    auth!
    process_notification(@feed, {:public_owner => current_user.id, :feed_name => @feed.name}, :action => 'destroy')
    @feed.destroy
    respond_with(@feed)
  end

private

  def feed_params
    types = Concerto::Application.config.content_types.map{|t| t.name.to_sym}
    params.require(:feed).permit(:name, :description, :parent_id, :group_id, :is_viewable, :is_submittable, :content_types => types)
  end

end
