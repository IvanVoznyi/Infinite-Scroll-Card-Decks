//
//  ContentView.swift
//  CardDeck
//
//  Created by Ivan Voznyi on 13.02.2024.
//

import SwiftUI

struct CardView: Identifiable {
    var id = UUID()
    var color: Color
}

let decks = [CardView(color: .black), CardView(color: .red), CardView(color: .green), CardView(color: .yellow), CardView(color: .accentColor), CardView(color: .brown)]

enum DragState {
    case inactive
    case pressing
    case dragging(translation: CGSize)
    
    var translation: CGSize {
        switch self {
        case .inactive, .pressing:
            return .zero
        case .dragging(let translation):
            return translation
        }
    }
    
    var isDragging: Bool {
        switch self {
        case .dragging:
            return true
        case .inactive, .pressing:
            return false
        }
    }
    
    var isPressing: Bool {
        switch self {
        case .pressing, .dragging:
            return true
        case .inactive:
            return false
        }
    }
}

struct ContentView: View {
    @GestureState private var dragState = DragState.inactive
    @State var zIndex = [decks[0].id: 1.0, decks[1].id: 0.0]
    @State var cardViews = [CardView](decks[0..<2].map { CardView(id: $0.id, color: $0.color) })
    @State private var removalTransition = AnyTransition.trailingBottom
    @State private var lastIndex = 1
    
    private let dragThreshold: CGFloat = 80.0
    
    var body: some View {
        ZStack {
            ForEach(cardViews) { card in
                RoundedRectangle(cornerRadius: 10)
                    .fill(card.color)
                    .padding()
                    .overlay {cardOverlay(card: card)}
                    .zIndex(zIndex[card.id] ?? 0)
                    .offset(x: self.isTopCard(cardView: card) ? self.dragState.translation.width : 0, y: self.isTopCard(cardView: card) ? self.dragState.translation.height : 0)
                    .scaleEffect(self.dragState.isDragging && self.isTopCard(cardView: card) ? 0.95 : 1.0)
                    .rotationEffect(Angle(degrees: self.isTopCard(cardView: card) ? Double( self.dragState.translation.width / 10) : 0))
                    .animation(.interpolatingSpring(stiffness: 180, damping: 100), value: self.dragState.translation)
                    .transition(removalTransition)
                    .gesture(cardGesture)
            }
        }
    }
    
    private var cardGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.01)
            .sequenced(before: DragGesture())
            .updating(self.$dragState, body: { (value, state, transaction) in
                switch value {
                case .first(true):
                    state = .pressing
                case .second(true, let drag):
                    state = .dragging(translation: drag?.translation ?? .zero)
                default:
                    break
                }
                
            })
            .onChanged({ (value) in
                guard case .second(true, let drag?) = value else {
                    return
                }
                
                if drag.translation.width < -self.dragThreshold {
                    self.removalTransition = .leadingBottom
                }
                
                if drag.translation.width > self.dragThreshold {
                    self.removalTransition = .trailingBottom
                }
                
            })
            .onEnded({ (value) in
                guard case .second(true, let drag?) = value else { return }
                
                if abs(drag.translation.width) > dragThreshold {
                    
                    withAnimation {
                        self.moveCard()
                    } completion: {
                        zIndex = [cardViews[0].id: 1.0, cardViews[1].id: 0.0]
                    }
                }
            })
    }
    
    private func cardOverlay(card: CardView) -> some View {
        ZStack {
            Image(systemName: "x.circle")
                .foregroundColor(.white)
                .font(.system(size: 100))
                .opacity(self.dragState.translation.width < -self.dragThreshold && isTopCard(cardView: card) ? 1.0 : 0)
            Image(systemName: "heart.circle")
                .foregroundColor(.white)
                .font(.system(size: 100))
                .opacity(self.dragState.translation.width > self.dragThreshold && self
                    .isTopCard(cardView: card) ? 1.0 : 0.0)
        }
    }
    
    private func isTopCard(cardView: CardView) -> Bool {
        if cardViews[0].id == cardView.id {
            return true
        }
        return false
    }
    
    private func moveCard() {
        cardViews.removeFirst()
        lastIndex += 1
        let card = decks[lastIndex % decks.count]
        let newCardView = CardView(id: card.id, color: card.color)
        zIndex = [cardViews[0].id: 0.0, newCardView.id: -1.0]
        cardViews.append(newCardView)
    }
}


#Preview {
    ContentView()
}

extension AnyTransition {
    static var trailingBottom: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .identity,
            removal: AnyTransition.move(edge: .trailing).combined(with: .move(edge: .bottom))
        )
        
    }
    
    static var leadingBottom: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .identity,
            removal: AnyTransition.move(edge: .leading).combined(with: .move(edge: .bottom))
        )
    }
}
