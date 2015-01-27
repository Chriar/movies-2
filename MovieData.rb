require 'csv'

class MovieData
	

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
	
	attr_reader:training_set
	attr_reader:test_set
	attr_reader:genre_set

	def load_data(file_name)
		indata = []
		#csv reader as shown in class; typecasted because I ran into some weird bugs
		CSV.foreach("#{file_name}", col_sep: "\t") do |row| 
			indata.push({"user_id"=>row[0].to_i, "movie_id"=>row[1].to_i, "rating" => row[2].to_i, "timestamp" => row[3].to_i})
		end
		return indata
	end

	def load_genre(file_name)
		indata = []
		CSV.foreach("#{file_name}", col_sep: "|") do |row|
			genre_for_movie = [row[5].to_i,row[6].to_i,row[7].to_i,row[8].to_i,row[9].to_i,row[10].to_i,row[11].to_i,row[12].to_i,row[13].to_i,row[14].to_i,row[15].to_i,row[16].to_i,row[17].to_i,row[18].to_i,row[19].to_i,row[20].to_i,row[21].to_i,row[22].to_i,row[23].to_i ]
			indata.push({"movie_id"=>row[0].to_i,"genres"=>genre_for_movie})
		end
		return indata
	end

	def rating(u,m)
		training_set.each do |row|
			if row["movie_id"] == m && row["user_id"] == u 
				return row["rating"]
			end
		end
		return 0
	end
	def movies(u)
		user_list = []
		training_set.each do |row|
			if row["user_id"] == u
				user_list.push({"movie_id"=>row["movie_id"], "rating"=>row["rating"], "genres"=>genre_set[row["movie_id"]-1]["genres"]})
				  				
			end
		end
		
		return user_list
	end
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
		m_genre.each_index do |x|
			if m_genre[x] == 1
				m_genre_index.push(x)
			end
		end
		#count,cumulative score will be averaged for average genre rating, then will take the average of that in order to get predicted score
		u_genre_rating = []
		counter = 0
		m_genre_index.each do |i|
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
		average = 0.0
		u_genre_rating.each do |b,t|
			if b != 0 && t != 0
				average += (t.to_f/b.to_f)
			end
		end
		return average/u_genre_rating.length
	end
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
	
	def initialize(result_list)
		@results = result_list
	end
	
	attr_reader:results
	
	def mean()
		average = 0.0
		@results.each do |row|
			average += (row["rating"].to_f - row["predicted"]).abs
		end

		return average/results.length
	end
	def stddev()
		mean = mean()
		av_error  = 0.0
		results.each do |row|
			av_error += ((row["rating"].to_f-row["predicted"].to_f).abs - mean)**2
		end
		tobesquared = av_error/results.length.to_f
		return Math.sqrt(tobesquared)
	end
	def rms
		sum = 0.0
		results.each do |row|
			sum += (row["rating"].to_f-row["predicted"].to_f).abs
		end
		sum /= results.length
		rms = Math.sqrt(sum)
		return rms
	end
	def to_a
		arr = []
		results.each do |row|
			arr.push([row["user_id"],row["movie_id"],row["rating"],row["predicted"]])
		end
		return arr
	end

end




z = MovieData.new("ml-100k",:u1)
#puts z.rating(22,377)
#puts z.movies(22)
#puts z.viewers(22)
#z.predict(1,1)
#puts z.run_test(140)