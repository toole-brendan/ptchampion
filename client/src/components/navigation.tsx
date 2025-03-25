import { Link } from "wouter";
import { Home, BookmarkIcon, User, Settings } from "lucide-react";

interface NavigationProps {
  active: "home" | "history" | "profile" | "settings";
}

export default function Navigation({ active }: NavigationProps) {
  return (
    <nav className="bg-white border-t border-slate-200 fixed bottom-0 left-0 right-0">
      <div className="container mx-auto px-4">
        <div className="flex justify-around">
          <Link href="/">
            <a className={`flex flex-col items-center justify-center p-2 text-xs font-medium ${active === "home" ? "text-accent" : "text-gray-500"}`}>
              <Home className="w-6 h-6 mb-1" />
              <span>Home</span>
            </a>
          </Link>
          <Link href="/history">
            <a className={`flex flex-col items-center justify-center p-2 text-xs font-medium ${active === "history" ? "text-accent" : "text-gray-500"}`}>
              <BookmarkIcon className="w-6 h-6 mb-1" />
              <span>History</span>
            </a>
          </Link>
          <Link href="/profile">
            <a className={`flex flex-col items-center justify-center p-2 text-xs font-medium ${active === "profile" ? "text-accent" : "text-gray-500"}`}>
              <User className="w-6 h-6 mb-1" />
              <span>Profile</span>
            </a>
          </Link>
          <Link href="/profile">
            <a className={`flex flex-col items-center justify-center p-2 text-xs font-medium ${active === "settings" ? "text-accent" : "text-gray-500"}`}>
              <Settings className="w-6 h-6 mb-1" />
              <span>Settings</span>
            </a>
          </Link>
        </div>
      </div>
    </nav>
  );
}
