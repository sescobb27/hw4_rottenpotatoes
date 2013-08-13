require 'spec_helper'

describe MoviesController do
  describe "GET #index" do
      let!(:movies) { mock_model('Movie') }
      before(:each) do
          Movie.stub(
          all_ratings: %w(G PG PG-13 NC-17 R),
          find_all_by_rating: [movies]
          )
          selected_ratings = Movie.all_ratings
          date_header = 'hilite'
      end

      it "should list all movies" do
          get :index
          response.status.should be 200
          response.should render_template :index
          (assigns[:movies]).should eq([movies])
      end

      it "should redirect to index" do
          params = {
              sort: 'release_date',
              ratings: {
                  'G' => '1',
                  'PG' => '1',
                  'PG-13' => '1',
                  'NC-17' => '1',
                  'R' => '1'
              }
          }
          get :index, params
          assigns[:selected_ratings]
          assigns[:date_header]
          assigns[:ordering]
          response.should redirect_to sort: params[:sort], ratings: params[:ratings]
      end
      it "should order movies by release_date" do
          params = {
              sort: 'release_date',
              ratings: {
                  'G' => '1',
                  'PG' => '1',
                  'PG-13' => '1',
                  'NC-17' => '1',
                  'R' => '1'
              }
          }
          ordering = {order: :release_date}

          session[:sort] = params[:sort]
          session[:ratings] = params[:ratings]

          Movie.should_receive(:find_all_by_rating).
              with(params[:ratings].keys, ordering)

          get :index, params

          assigns[:date_header]
          assigns[:selected_ratings]
          assigns[:ordering]
          
          (session[:sort]).should eql params[:sort]
          (session[:ratings]).should eql params[:ratings]
          response.should render_template(:index)
          (assigns[:movies]).should eql([movies])
          
      end
  end

  describe "POST #create" do
      let!(:movie) { stub_model(Movie) }
      before(:each) do
          Movie.stub(:create!).and_return(movie)
      end
      it "should send new  message  to Movies class" do
          params = {
                      'title' => 'X-Men',
                      'director' => 'Stan Lee',
                      'rating' => 'G',
                      'release_date' => '1971-03-11'
                  }
          Movie.should_receive(:create!).with(params)
          post :create, movie: params
      end

      context "when create" do
          it "should redirect_to index" do
             post :create
             (response).should redirect_to movies_path
          end
          it "should assigns a success flash message" do
              post :create
              (flash[:notice]).should_not be_nil
          end
      end

=begin
      context "when error" do
          before(:each) do
              Movie.stub(:create!).and_raise(ActiveRecord::RecordInvalid.new movie) 
          end
          it "should re-render the new view" do
              expect(Movie.should_receive(:create!)).to raise_error ActiveRecord::RecordInvalid
              post :create
              response.should render_template action: 'new'
              expect(flash[:notice]).not_to be_nil
          end
      end
=end
  end

  describe "PUT #Update" do
      let!(:movie) { stub_model(Movie) }
      before(:each) do
          Movie.stub(:find).and_return(movie)
      end

      describe "find movies" do
          it "should be in edit page" do
              params = {
                  id: '1'
              }
              Movie.should_receive(:find).with(params[:id])
              get :edit, params
              response.should render_template :edit
          end

          it "should update movies director" do
              params = {
                  id: '1',
                  movie: {
                      'director'=> 'Stan Lee'
                  }
              }
              Movie.should_receive(:find).with(params[:id])
              movie.should_receive(:update_attributes!).with(params[:movie])
              put :update, params
          end

          it "should display flash" do
              params = {
                  id: '1'
              }
              flash.should_not be(nil)
              put :update, params
          end

          it "should redirect to show movie path" do
              params = {
                  id: '1'
              }
              put :update, params
              response.should redirect_to(movie_path(movie))
          end
      end
      it "updated movies director should be the same requested" do
          params = {
              id: '1',
              movie: {
                  'director' => 'Stan Lee'
              }
          }
          put :update, params
          assigns([:movie])
          (movie.director).should eql params[:movie]['director']
      end
  end

  describe "GET #Same_director" do
      let!(:movie) { stub_model(Movie) }
      before(:each) do
          Movie.stub(:find).and_return(movie)
          movie.stub(:release_date).and_return(Time.zone.parse '1977-05-25 00:00:00')
          movie.stub(:title).and_return('Star Wars')
      end
      context "movies with same director" do
          describe "find" do
              it "should send find message to Movie.class" do
                  params = {
                      id: '1'
                  }
                  Movie.should_receive(:find).with(params[:id])
                  get :show, params
                  response.should render_template(:show)
                  assigns[:movie]
              end

              # it "should see other movies with same director" do
              #     params = {
              #         title: 'Star Wars'
              #     }
              #     Movie.stub_chain(:select, :where, :first) do 
              #         mock_model("Movie", director: 'George Lucas')
              #     end
              #     Movie.should_receive(:find_all_by_director).with(Movie.select.where.first)
              #     movies = Movie.stub(:find_all_by_director).and_return [
              #         mock_model("Movie", title: 'Star Wars'),
              #         mock_model("Movie", title: 'THX-1138')
              #     ]
              #     puts "movies: #{movies}"
              #     get :same_director, params
              #     p response.body
              #     response.should render_template(:same_director)
              #     response.body.should have_content("Star Wars")
              #     response.body.should have_content("THX-1138")
              #     response.body.should_not have_content("Blade Runner")
              #     assigns[:movies]
                  
              # end
          end

          describe "can't find" do
              it "should redirect if not movies were found"do
                  params = {
                      title: 'Invalid'
                  }
                  Movie.stub_chain(:select, :where, :first) do
                      nil
                  end
                  get :same_director, params
                  (response).should redirect_to(movies_path)
                  (flash).should_not be_nil
              end
              it "should show flash 'movie title' has no director info" do
                  params = {
                      title: 'Alien'
                  }
                  Movie.stub_chain(:select, :where, :first) do
                      mock_model("Movie", director: '')
                  end
                  get :same_director, params
                  (response).should redirect_to(movies_path)
                  (flash[:notice]).should eql "'Alien' has no director info"
              end
          end
      end
    end
end
