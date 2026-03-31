import Link from "next/link";

export default function HomePage() {
  return (
    <div className="min-h-screen bg-background">
      <nav className="border-b">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <span className="text-2xl font-bold text-primary">🐾 WoofTalk</span>
          <div className="flex gap-4">
            <Link href="/auth/signin" className="text-muted-foreground hover:text-foreground">Sign In</Link>
            <Link href="/translate" className="text-muted-foreground hover:text-foreground">Translate</Link>
            <Link href="/community" className="text-muted-foreground hover:text-foreground">Community</Link>
            <Link href="/translate" className="px-4 py-2 bg-primary text-primary-foreground rounded-lg">Translate</Link>
          </div>
        </div>
      </nav>

      <main className="container mx-auto px-4 py-16 text-center max-w-3xl">
        <h1 className="text-5xl font-bold mb-6">Translate Between Human & Animal Languages</h1>
        <p className="text-xl text-muted-foreground mb-8">
          Communicate with your pet like never before. Translate human text to Dog, Cat, or Bird language — and back again.
        </p>
        <Link
          href="/translate"
          className="inline-block px-8 py-4 bg-primary text-primary-foreground rounded-lg text-lg font-medium hover:bg-primary/90 transition-colors"
        >
          Start Translating
        </Link>

        <div className="grid md:grid-cols-3 gap-8 mt-16">
          <div className="p-6 bg-card rounded-lg border">
            <div className="text-4xl mb-4">🐕</div>
            <h3 className="text-lg font-semibold mb-2">Dog Language</h3>
            <p className="text-muted-foreground">Woof, bark, arf — understand what your dog is saying</p>
          </div>
          <div className="p-6 bg-card rounded-lg border">
            <div className="text-4xl mb-4">🐈</div>
            <h3 className="text-lg font-semibold mb-2">Cat Language</h3>
            <p className="text-muted-foreground">Meow, purr, hiss — decode your cat&apos;s messages</p>
          </div>
          <div className="p-6 bg-card rounded-lg border">
            <div className="text-4xl mb-4">🐦</div>
            <h3 className="text-lg font-semibold mb-2">Bird Language</h3>
            <p className="text-muted-foreground">Chirp, tweet, whistle — translate bird sounds</p>
          </div>
        </div>
      </main>
    </div>
  );
}
