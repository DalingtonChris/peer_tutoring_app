import { useState } from 'react';

const COURSES = ["IOT", "Networking", "Software Engineering", "Computer Science", "Cybersecurity", "Data Structures", "Algorithms", "Machine Learning"];

const INITIAL_STUDENTS = [
  { id: 1, name: "Nju Nicolas", role: "tutor", expertise: ["IOT", "Networking"], bio: "Senior IOT student.", rating: 4.8 },
  { id: 2, name: "JayCole Makia", role: "tutor", expertise: ["Software Engineering"], bio: "Full-stack dev.", rating: 4.9 },
  { id: 3, name: "Agbor Eden", role: "learner", needs: ["IOT"], bio: "Freshman struggling with IOT." },
  { id: 4, name: "Manuella Kengne", role: "tutor", expertise: ["Computer Science", "Data Structures"], bio: "CS enthusiast.", rating: 4.7 },
  { id: 5, name: "Michael Chilla", role: "learner", needs: ["Software Engineering"], bio: "Looking to improve coding skills." },
  { id: 6, name: "Souley Amina", role: "tutor", expertise: ["Cybersecurity", "Machine Learning"], bio: "Cybersecurity expert.", rating: 4.9 },
  { id: 7, name: "Otou Eric", role: "learner", needs: ["Cybersecurity"], bio: "Interested in cybersecurity careers." },
  { id: 8, name: "Van Brown", role: "tutor", expertise: ["Algorithms"], bio: "Competitive programmer.", rating: 4.6 },
];
 
const PeerTutoringApp = () => {
  const [view, setView] = useState('dashboard'); // dashboard, profile, matches
  const [currentUser] = useState(INITIAL_STUDENTS[2]); // Defaulting to a Learner
  const [tutors] = useState(INITIAL_STUDENTS.filter(s => s.role === 'tutor'));
  const [matches, setMatches] = useState([]);

  // Matching Logic: Find tutors who teach what the learner needs
  const findMatches = () => {
    if (currentUser.role === 'learner') {
      const suggested = tutors.filter(tutor => 
        tutor.expertise.some(skill => currentUser.needs.includes(skill))
      );
      setMatches(suggested);
      setView('matches');
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 font-sans">
      {/* Navigation */}
      <nav className="bg-indigo-600 p-4 text-white flex justify-between items-center shadow-lg">
        <h1 className="text-xl font-bold">PeerLearn P2P</h1>
        <div className="space-x-4">
          <button onClick={() => setView('dashboard')} className="hover:underline">Courses</button>
          <button onClick={() => setView('matches')} className="hover:underline">My Matches</button>
          <button onClick={() => setView('profile')} className="bg-indigo-800 px-3 py-1 rounded-full text-sm">
            {currentUser.name} ({currentUser.role})
          </button>
        </div>
      </nav>

      <main className="p-6 max-w-6xl mx-auto">
        
        {/* DASHBOARD: COURSE LISTING */}
        {view === 'dashboard' && (
          <div>
            <h2 className="text-2xl font-bold mb-4">Available Courses</h2>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              {COURSES.map(course => (
                <div key={course} className="bg-white p-6 rounded-xl shadow-sm border border-gray-200 hover:shadow-md transition">
                  <h3 className="text-lg font-semibold text-indigo-700">{course}</h3>
                  <p className="text-gray-500 text-sm mt-2">10+ Tutors available</p>
                  <button 
                    onClick={findMatches}
                    className="mt-4 w-full bg-indigo-50 text-indigo-600 py-2 rounded-lg font-medium hover:bg-indigo-100"
                  >
                    Find a Tutor
                  </button>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* MATCHING SYSTEM VIEW */}
        {view === 'matches' && (
          <div>
            <h2 className="text-2xl font-bold mb-4">Recommended Tutors for You</h2>
            {matches.length > 0 ? (
              <div className="grid grid-cols-1 gap-4">
                {matches.map(tutor => (
                  <div key={tutor.id} className="bg-white p-4 rounded-lg shadow flex items-center justify-between border-l-4 border-green-500">
                    <div>
                      <h3 className="font-bold text-lg">{tutor.name}</h3>
                      <p className="text-gray-600 text-sm">{tutor.bio}</p>
                      <div className="flex mt-2">
                        {tutor.expertise.map(skill => (
                          <span key={skill} className="bg-blue-100 text-blue-800 text-xs px-2 py-1 rounded mr-2">{skill}</span>
                        ))}
                      </div>
                    </div>
                    <div className="text-right">
                      <p className="text-yellow-600 font-bold">⭐ {tutor.rating}</p>
                      <button className="mt-2 bg-indigo-600 text-white px-4 py-2 rounded-lg text-sm">Request Session</button>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <p>No matches found yet. Try selecting a course first!</p>
            )}
          </div>
        )}

        {/* PROFILE VIEW */}
        {view === 'profile' && (
          <div className="max-w-2xl mx-auto bg-white p-8 rounded-2xl shadow">
            <div className="text-center mb-6">
              <div className="w-24 h-24 bg-gray-200 rounded-full mx-auto mb-4 flex items-center justify-center text-3xl font-bold text-gray-500">
                {currentUser.name[0]}
              </div>
              <h2 className="text-2xl font-bold">{currentUser.name}</h2>
              <span className="capitalize text-indigo-600 font-medium">{currentUser.role}</span>
            </div>
            
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700">Bio</label>
                <p className="text-gray-600 mt-1">{currentUser.bio}</p>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  {currentUser.role === 'tutor' ? 'Teaching Courses' : 'Need Help With'}
                </label>
                <div className="flex flex-wrap gap-2 mt-2">
                  {(currentUser.expertise || currentUser.needs).map(c => (
                    <span key={c} className="bg-gray-100 px-3 py-1 rounded-full text-sm">{c}</span>
                  ))}
                </div>
              </div>
            </div>
            <button className="mt-8 w-full border border-gray-300 py-2 rounded-lg text-gray-600 hover:bg-gray-50">Edit Profile</button>
          </div>
        )}

      </main>
    </div>
  );
};

export default PeerTutoringApp;