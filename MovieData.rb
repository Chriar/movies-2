require 'csv'

class MovieData
	
	#cant remember if you can use two separate initializers in ruby
	def initialize(folder,test=nil)
		if test != nil
			@training_set = load_data("#{folder}/#{test.to_s}.base")
			@test_set = load_data("#{folder}/#{test.to_s}.test")
			@genre_set = load_genre("#{folder}/u.item")
		else
			@training_set = load_data("#{folder}/u.data")
			@genre_set = load_genre("#{folder}/u.item")
		end
	end
	#global attributes
	attr_reader:training_set
	attr_reader:test_set
	attr_reader:genre_set

	#loads data using csv
	def load_data(file_name)
		indata = []
		#csv reader as shown in class; typecasted because I ran into some weird bugs
		CSV.foreach("#{file_name}", col_sep: "\t") do |row| 
			indata.push({"user_id"=>row[0].to_i, "movie_id"=>row[1].to_i, "rating" => row[2].to_i, "timestamp" => row[3].to_i})
		end
		return indata
	end

	#for predict I decided to use genres instead of similarity. Not really sure why I did that CSV with | as the col sep
	#there must be an easier way to add the value at indexes 5-23 to genre_for_movie
	#fails complexity tests
	def load_genre(file_name)
		indata = []
		CSV.foreach("#{file_name}", col_sep: "|") do |row|
			genre_for_movie = [row[5].to_i,row[6].to_i,row[7].to_i,row[8].to_i,row[9].to_i,row[10].to_i,row[11].to_i,row[12].to_i,row[13].to_i,row[14].to_i,row[15].to_i,row[16].to_i,row[17].to_i,row[18].to_i,row[19].to_i,row[20].to_i,row[21].to_i,row[22].to_i,row[23].to_i ]
			indata.push({"movie_id"=>row[0].to_i,"genres"=>genre_for_movie})
		end
		return indata
	end

	#looks through the training set and if the movie id = m and userof == u then returns the rating at that row
	def rating(u,m)
		training_set.each do |row|
			if row["movie_id"] == m && row["user_id"] == u 
				return row["rating"]
			end
		end
		return 0
	end

	#gets a list of movies watched by the user and pushes the row and genres to the array
	def movies(u)
		user_list = []
		training_set.each do |row|
			if row["user_id"] == u
				user_list.push({"movie_id"=>row["movie_id"], "rating"=>row["rating"], "genres"=>genre_set[row["movie_id"]-1]["genres"]})
				  				
			end
		end
		
		return user_list
	end
	#creates a list of users that saw the movie and the rating they gave
	#if used similarity score would use this as the comparison list using most similar in movies-1
	def viewers(m)
		viewer_list = []
		training_set.each do |row|
			if row["movie_id"] == m
				viewer_list.push({"user_id"=>row["user_id"],"rating"=>row["rating"]})
			end
		end
		return viewer_list
	end


	def predict(u,m)
		user_list = movies(u)
		m_genre = genre_set[m-1]["genres"]
		m_genre_index = []
		#pushes which genres this movie has
		m_genre.each_index do |x|
			if m_genre[x] == 1
				m_genre_index.push(x)
			end
		end
		#count,cumulative score will be averaged for average genre rating, then will take the average of that in order to get predicted score
		u_genre_rating = []
		counter = 0
		m_genre_index.each do |i|
			#u_genre_rating[0] is the count, u_genre_rating[1] is the cumulative total
			u_genre_rating.push([0,0])
			user_list.each do |row|
				test_genres = row["genres"]
				if test_genres[i] == 1 
					temp1 = u_genre_rating[counter][0]
					temp2 = u_genre_rating[counter][1]
					u_genre_rating[counter] = [temp1+1,row["rating"]+temp2]
				end
			end
			counter +=1
		end
		#total average
		average = 0.0
		u_genre_rating.each do |b,t|
			if b != 0 && t != 0
				average += (t.to_f/b.to_f)
			end
		end
		#bugs galore to get here
		return average/u_genre_rating.length
	end

	#sends all values that are going to be in the movietest object to an array and returns the movie test object
	def run_test(k)
		to_movietest = []
		(0..k).each do |i|
			row = @test_set[i]
			pred = predict(row["user_id"],row["movie_id"])
			to_movietest.push({"user_id"=>row["user_id"],"movie_id"=>row["movie_id"],"rating"=>row["rating"],"predicted"=>pred})
		end
		t = MovieTest.new(to_movietest)
		return t
	end
end

class MovieTest
	
	#initialized base on a list passed by run test
	def initialize(result_list)
		@results = result_list
	end
	
	attr_reader:results
	
	#gets the mean of error as a float
	def mean()
		average = 0.0
		@results.each do |row|
			average += (row["rating"].to_f - row["predicted"]).abs
		end

		return average/results.length
	end
	#get stddev of the error
	def stddev()
		mean = mean()
		av_error  = 0.0
		results.each do |row|
			av_error += ((row["rating"].to_f-row["predicted"].to_f).abs - mean)**2
		end
		tobesquared = av_error/results.length.to_f
		return Math.sqrt(tobesquared)
	end

	#get root mean square as a float. think this is where the error occurred
	def rms
		sum = 0.0
		results.each do |row|
			sum += (row["rating"].to_f-row["predicted"].to_f).abs
		end
		sum /= results.length
		rms = Math.sqrt(sum)
		return rms
	end
	#cast each row to an array and returns it
	def to_a
		arr = []
		results.each do |row|
			arr.push([row["user_id"],row["movie_id"],row["rating"],row["predicted"]])
		end
		return arr
	end

end

#NOTES I HAD A NAN ERROR AT SOME POINT, NOT EXACTLY AN ERROR BUT IT WOULD CHANGE THE AVERAGE TO NAN. DONT REMEMBER WHAT CAUSED IT

#z = MovieData.new("ml-100k",:u1)
#puts z.rating(22,377)
#puts z.movies(22)
#puts z.viewers(22)
#z.predict(1,1)
#puts z.run_test(140)