var fs  = require('fs');

exports.index = (req, res) => {
	fs.readdir('public/images/Linden', function(err, lindenData){
		fs.readdir('public/images/golfview', function(err, golfviewData){
			fs.readdir('public/images/tuscany', function(err, tuscanyData){
				fs.readdir('public/images/fairhope', function(err, fairhopeData){
					fs.readdir('public/images/queens', function(err, queensData){
						res.render('examples', {
							title: 'Examples',
							linden: lindenData,
							golfview: golfviewData,
							tuscany: tuscanyData,
							fairhope: fairhopeData,
							queens: queensData
						});
					});
				});
			});
		});
	});
};